RSpec.describe Epics::Services::CryptService do
  subject(:service) { described_class.new }

  let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:rsa_algo) { Epics::SignatureAlgorithm::Rsa.new(rsa_key) }

  describe '#sign' do
    let(:data) { 'test data to sign' }

    context 'with A006 (RSA-PSS)' do
      let(:signature) { Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo) }

      it 'returns a valid RSA-PSS signature' do
        sig = service.sign(signature, data)
        expect(sig).to be_a(String)
        expect(sig.bytesize).to eq(rsa_key.n.num_bytes)
      end

      it 'produces a signature verifiable with RSA-PSS' do
        sig = service.sign(signature, data)
        valid = rsa_key.verify_pss('SHA256', sig, data, salt_length: 32, mgf1_hash: 'SHA256')
        expect(valid).to be true
      end

      it 'produces different signatures for different data' do
        sig1 = service.sign(signature, 'data one')
        sig2 = service.sign(signature, 'data two')
        expect(sig1).not_to eq(sig2)
      end

      it 'produces non-deterministic signatures (PSS uses random salt)' do
        sig1 = service.sign(signature, data)
        sig2 = service.sign(signature, data)
        expect(sig1).not_to eq(sig2)
      end
    end

    context 'with A005 (PKCS#1 v1.5)' do
      let(:signature) { Epics::Signature.new(Epics::Signature::A_VERSION_5, rsa_algo) }

      it 'returns a valid PKCS#1 v1.5 signature' do
        sig = service.sign(signature, data)
        expect(sig).to be_a(String)
        expect(sig.bytesize).to eq(rsa_key.n.num_bytes)
      end

      it 'produces a signature verifiable with PKCS#1 v1.5' do
        sig = service.sign(signature, data)
        valid = rsa_key.verify('SHA256', sig, data)
        expect(valid).to be true
      end

      it 'produces deterministic signatures' do
        sig1 = service.sign(signature, data)
        sig2 = service.sign(signature, data)
        expect(sig1).to eq(sig2)
      end
    end
  end

  describe '#encrypt' do
    let(:data) { 'data to encrypt' }
    let(:rsa_pss_algo) { Epics::SignatureAlgorithm::RsaPss.new(rsa_key) }

    context 'with A006 (RSA-PSS sign)' do
      let(:signature) { Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_pss_algo) }

      it 'delegates to signature_algorithm#sign' do
        expect(rsa_pss_algo).to receive(:sign).with(data).and_call_original
        service.encrypt(signature, data)
      end
    end

    context 'with X002' do
      let(:signature) { Epics::Signature.new(Epics::Signature::X_VERSION_2, rsa_pss_algo) }

      it 'delegates to signature_algorithm#sign' do
        expect(rsa_pss_algo).to receive(:sign).with(data).and_call_original
        service.encrypt(signature, data)
      end
    end

    context 'with A005 (RSA PKCS#1 private encrypt)' do
      let(:signature) { Epics::Signature.new(Epics::Signature::A_VERSION_5, rsa_algo) }

      it 'delegates to signature_algorithm#private_encrypt' do
        expect(rsa_algo).to receive(:private_encrypt).with(data).and_call_original
        service.encrypt(signature, data)
      end
    end
  end

  describe '#encrypt_by_key / #decrypt_by_key' do
    let(:plaintext) { 'Hello EBICS world!' }

    it 'round-trips: decrypt(encrypt(data)) == data' do
      aes_key = OpenSSL::Cipher::AES.new(128, :CBC).random_key
      encrypted = service.encrypt_by_key(aes_key, plaintext)
      decrypted = service.decrypt_by_key(aes_key, encrypted)
      expect(decrypted).to eq(plaintext)
    end

    it 'produces ciphertext different from plaintext' do
      aes_key = OpenSSL::Cipher::AES.new(128, :CBC).random_key
      encrypted = service.encrypt_by_key(aes_key, plaintext)
      expect(encrypted).not_to eq(plaintext)
    end

    it 'produces different ciphertext with different keys' do
      key1 = OpenSSL::Cipher::AES.new(128, :CBC).random_key
      key2 = OpenSSL::Cipher::AES.new(128, :CBC).random_key
      enc1 = service.encrypt_by_key(key1, plaintext)
      enc2 = service.encrypt_by_key(key2, plaintext)
      expect(enc1).not_to eq(enc2)
    end
  end

  describe '#encrypt_transaction_key' do
    it 'encrypts with RSA public key and is decryptable with private key' do
      transaction_key = OpenSSL::Cipher::AES.new(128, :CBC).random_key
      encrypted = service.encrypt_transaction_key(rsa_algo, transaction_key)
      decrypted = rsa_key.private_decrypt(encrypted)
      expect(decrypted).to eq(transaction_key)
    end
  end

  describe '#hash' do
    it 'returns SHA256 digest by default' do
      result = service.hash('test')
      expect(result).to eq(OpenSSL::Digest::SHA256.digest('test'))
    end

    it 'supports alternative algorithms' do
      result = service.hash('test', 'sha512')
      expect(result).to eq(OpenSSL::Digest::SHA512.digest('test'))
    end

    it 'returns binary digest' do
      result = service.hash('test')
      expect(result.encoding).to eq(Encoding::BINARY)
    end
  end

  describe '#calculate_digest' do
    it 'returns SHA256 hash of "exponent modulus" (hex, lowercase, no leading zeros)' do
      exponent_hex = rsa_key.e.to_s(16).gsub(/^0*/, '').downcase
      modulus_hex = rsa_key.n.to_s(16).gsub(/^0*/, '').downcase
      expected = OpenSSL::Digest::SHA256.digest("#{exponent_hex} #{modulus_hex}")

      result = service.calculate_digest(rsa_algo)
      expect(result).to eq(expected)
    end

    it 'strips leading zeros from exponent and modulus' do
      key_text = service.calculate_key('000ABC', '00DEF123')
      expect(key_text).to eq('abc def123')
    end
  end

  describe '#calculate_key' do
    it 'concatenates exponent and modulus lowercase without leading zeros' do
      expect(service.calculate_key('10001', 'ABCDEF')).to eq('10001 abcdef')
    end

    it 'strips leading zeros' do
      expect(service.calculate_key('010001', '00ABCDEF')).to eq('10001 abcdef')
    end
  end

  describe '#calculate_certificate_fingerprint' do
    let(:dn) { '/C=DE/O=TestBank/CN=test.ebics.org' }
    let(:cert_pem) { generate_x_509_crt(rsa_key, dn) }
    let(:x509) { Epics::Crypt::X509.new(cert_pem) }

    it 'returns SHA256 hash of DER-encoded certificate' do
      expected = OpenSSL::Digest::SHA256.digest(x509.to_der)
      result = service.calculate_certificate_fingerprint(x509)
      expect(result).to eq(expected)
    end

    it 'returns binary digest' do
      result = service.calculate_certificate_fingerprint(x509)
      expect(result.encoding).to eq(Encoding::BINARY)
    end
  end
end

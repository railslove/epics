RSpec.describe 'DigestResolver' do
  let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:rsa_algo) { Epics::SignatureAlgorithm::Rsa.new(rsa_key) }
  let(:dn) { '/C=DE/O=TestBank/CN=test.ebics.org' }
  let(:cert_pem) { generate_x_509_crt(rsa_key, dn) }
  let(:x509) { Epics::Crypt::X509.new(cert_pem) }
  let(:crypt_service) { Epics::Services::CryptService.new }

  describe Epics::Services::DigestResolver::Base do
    subject(:resolver) { described_class.new }

    it 'raises NotImplementedError for sign_digest' do
      sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
      expect { resolver.sign_digest(sig) }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for confirm_digest' do
      sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
      expect { resolver.confirm_digest(sig) }.to raise_error(NotImplementedError)
    end
  end

  describe Epics::Services::DigestResolver::V2 do
    subject(:resolver) { described_class.new }

    describe '#sign_digest' do
      it 'returns binary SHA256 hash of key (exponent + modulus)' do
        sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
        result = resolver.sign_digest(sig)
        expected = crypt_service.calculate_digest(rsa_algo)
        expect(result).to eq(expected)
      end

      it 'uses key-based digest regardless of certificate presence' do
        sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
        sig.certificate = x509
        result = resolver.sign_digest(sig)
        expected = crypt_service.calculate_digest(rsa_algo)
        expect(result).to eq(expected)
      end

      it 'returns binary (not hex) data' do
        sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
        result = resolver.sign_digest(sig)
        expect(result.encoding).to eq(Encoding::BINARY)
      end
    end

    describe '#confirm_digest' do
      context 'without certificate' do
        it 'returns hex-encoded SHA256 hash of key' do
          sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
          result = resolver.confirm_digest(sig)
          expected_binary = crypt_service.calculate_digest(rsa_algo)
          expected_hex = expected_binary.unpack1('H*')
          expect(result).to eq(expected_hex)
        end
      end

      context 'with certificate' do
        it 'returns hex-encoded SHA256 hash of certificate DER' do
          sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
          sig.certificate = x509
          result = resolver.confirm_digest(sig)
          expected_binary = crypt_service.calculate_certificate_fingerprint(x509)
          expected_hex = expected_binary.unpack1('H*')
          expect(result).to eq(expected_hex)
        end

        it 'uses certificate fingerprint instead of key digest' do
          sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
          sig.certificate = x509

          key_digest_hex = crypt_service.calculate_digest(rsa_algo).unpack1('H*')
          cert_digest_hex = resolver.confirm_digest(sig)
          expect(cert_digest_hex).not_to eq(key_digest_hex)
        end
      end

      it 'returns a hex string (lowercase, 64 chars for SHA256)' do
        sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
        result = resolver.confirm_digest(sig)
        expect(result).to match(/\A[0-9a-f]{64}\z/)
      end
    end

    describe 'sign_digest vs confirm_digest difference' do
      it 'sign_digest returns binary, confirm_digest returns hex of same value (without cert)' do
        sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
        sign_result = resolver.sign_digest(sig)
        confirm_result = resolver.confirm_digest(sig)
        expect(confirm_result).to eq(sign_result.unpack1('H*'))
      end
    end
  end

  describe Epics::Services::DigestResolver::V3 do
    subject(:resolver) { described_class.new }

    let(:sig_with_cert) do
      sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
      sig.certificate = x509
      sig
    end

    describe '#sign_digest' do
      it 'returns binary SHA256 hash of certificate DER' do
        result = resolver.sign_digest(sig_with_cert)
        expected = crypt_service.calculate_certificate_fingerprint(x509)
        expect(result).to eq(expected)
      end

      it 'returns binary data' do
        result = resolver.sign_digest(sig_with_cert)
        expect(result.encoding).to eq(Encoding::BINARY)
      end

      it 'raises error without certificate' do
        sig = Epics::Signature.new(Epics::Signature::A_VERSION_6, rsa_algo)
        expect { resolver.sign_digest(sig) }.to raise_error(NoMethodError)
      end
    end

    describe '#confirm_digest' do
      it 'returns hex-encoded SHA256 hash of certificate DER' do
        result = resolver.confirm_digest(sig_with_cert)
        expected_binary = crypt_service.calculate_certificate_fingerprint(x509)
        expected_hex = expected_binary.unpack1('H*')
        expect(result).to eq(expected_hex)
      end

      it 'returns a hex string (lowercase, 64 chars for SHA256)' do
        result = resolver.confirm_digest(sig_with_cert)
        expect(result).to match(/\A[0-9a-f]{64}\z/)
      end
    end

    describe 'sign_digest vs confirm_digest relationship' do
      it 'confirm_digest is hex encoding of sign_digest' do
        sign_result = resolver.sign_digest(sig_with_cert)
        confirm_result = resolver.confirm_digest(sig_with_cert)
        expect(confirm_result).to eq(sign_result.unpack1('H*'))
      end
    end

    describe 'V3 uses certificate, not key' do
      it 'produces different digest than V2 sign_digest (key-based)' do
        v2 = Epics::Services::DigestResolver::V2.new
        v2_result = v2.sign_digest(sig_with_cert)
        v3_result = resolver.sign_digest(sig_with_cert)
        expect(v3_result).not_to eq(v2_result)
      end
    end
  end
end

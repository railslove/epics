RSpec.describe Epics::Keyring do
  describe '#initialize' do
    it 'accepts VERSION_24 (H003)' do
      keyring = described_class.new(Epics::Keyring::VERSION_24)
      expect(keyring.version).to eq('H003')
    end

    it 'accepts VERSION_25 (H004)' do
      keyring = described_class.new(Epics::Keyring::VERSION_25)
      expect(keyring.version).to eq('H004')
    end

    it 'accepts VERSION_30 (H005)' do
      keyring = described_class.new(Epics::Keyring::VERSION_30)
      expect(keyring.version).to eq('H005')
    end

    it 'raises ArgumentError for unsupported version' do
      expect { described_class.new('H006') }.to raise_error(ArgumentError, /Unsupported version/)
    end

    it 'raises ArgumentError for nil' do
      expect { described_class.new(nil) }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError for empty string' do
      expect { described_class.new('') }.to raise_error(ArgumentError)
    end
  end

  describe 'version is immutable' do
    it 'does not have a version= writer' do
      keyring = described_class.new(Epics::Keyring::VERSION_25)
      expect(keyring).not_to respond_to(:version=)
    end
  end

  describe 'constants' do
    it 'defines VERSION_24 as H003' do
      expect(Epics::Keyring::VERSION_24).to eq('H003')
    end

    it 'defines VERSION_25 as H004' do
      expect(Epics::Keyring::VERSION_25).to eq('H004')
    end

    it 'defines VERSION_30 as H005' do
      expect(Epics::Keyring::VERSION_30).to eq('H005')
    end

    it 'VERSIONS contains all three versions' do
      expect(Epics::Keyring::VERSIONS).to contain_exactly('H003', 'H004', 'H005')
    end
  end

  describe 'key accessors' do
    subject(:keyring) { described_class.new(Epics::Keyring::VERSION_25) }
    let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }

    it 'stores and retrieves user_signature' do
      sig = Epics::Signature.new(Epics::Signature::A_VERSION_5, Epics::SignatureAlgorithm::RsaPkcs1.new(rsa_key))
      keyring.user_signature = sig
      expect(keyring.user_signature).to eq(sig)
    end

    it 'stores and retrieves user_authentication' do
      sig = Epics::Signature.new(Epics::Signature::X_VERSION_2, Epics::SignatureAlgorithm::RsaPkcs1.new(rsa_key))
      keyring.user_authentication = sig
      expect(keyring.user_authentication).to eq(sig)
    end

    it 'stores and retrieves user_encryption' do
      sig = Epics::Signature.new(Epics::Signature::E_VERSION_2, Epics::SignatureAlgorithm::RsaPkcs1.new(rsa_key))
      keyring.user_encryption = sig
      expect(keyring.user_encryption).to eq(sig)
    end

    it 'stores and retrieves bank_authentication' do
      sig = Epics::Signature.new(Epics::Signature::X_VERSION_2, Epics::SignatureAlgorithm::RsaPkcs1.new(rsa_key))
      keyring.bank_authentication = sig
      expect(keyring.bank_authentication).to eq(sig)
    end

    it 'stores and retrieves bank_encryption' do
      sig = Epics::Signature.new(Epics::Signature::E_VERSION_2, Epics::SignatureAlgorithm::RsaPkcs1.new(rsa_key))
      keyring.bank_encryption = sig
      expect(keyring.bank_encryption).to eq(sig)
    end

    it 'all key slots are nil by default' do
      expect(keyring.user_signature).to be_nil
      expect(keyring.user_authentication).to be_nil
      expect(keyring.user_encryption).to be_nil
      expect(keyring.bank_authentication).to be_nil
      expect(keyring.bank_encryption).to be_nil
    end
  end

  describe 'key serialization round-trip via Client' do
    let(:passphrase) { 'test_passphrase' }
    let(:client) do
      Epics::Client.setup(passphrase, 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01', 2048)
    end

    it 'dump_keys produces valid JSON' do
      json = client.send(:dump_keys)
      parsed = JSON.parse(json)
      expect(parsed).to be_a(Hash)
      expect(parsed.keys).to include('A006', 'X002', 'E002')
    end

    it 'keys survive save and reload' do
      original_keys = client.keys
      json = client.send(:dump_keys)

      reloaded = Epics::Client.new(json, passphrase, 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01')

      # Compare public digests to verify same keys
      expect(reloaded.signature_key.public_digest).to eq(original_keys['A006'].public_digest)
      expect(reloaded.authentication_key.public_digest).to eq(original_keys['X002'].public_digest)
      expect(reloaded.encryption_key.public_digest).to eq(original_keys['E002'].public_digest)
    end

    it 'keys are encrypted (not plaintext PEM)' do
      json = client.send(:dump_keys)
      parsed = JSON.parse(json)
      parsed.each_value do |encrypted_key|
        # Values may be plain strings (user keys) or hashes with 'key'/'cert' (bank keys with certs)
        values_to_check = encrypted_key.is_a?(Hash) ? encrypted_key.values : [encrypted_key]
        values_to_check.each do |v|
          expect(v).not_to include('BEGIN RSA PRIVATE KEY')
          expect(v).not_to include('BEGIN PRIVATE KEY')
          expect(v).not_to include('BEGIN CERTIFICATE')
        end
      end
    end

    it 'decrypt fails with wrong passphrase' do
      json = client.send(:dump_keys)
      expect do
        Epics::Client.new(json, 'wrong_passphrase', 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01')
      end.to raise_error(OpenSSL::Cipher::CipherError)
    end
  end

  describe 'bank certificate serialization round-trip' do
    let(:passphrase) { 'test_passphrase' }
    let(:client) do
      Epics::Client.setup(passphrase, 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01', 2048,
                          version: Epics::Keyring::VERSION_30)
    end
    let(:dn) { '/C=CH/O=TestBank/CN=test.ebics.org' }

    before do
      # Simulate HPB: create bank key signatures with certificates
      %i[bank_authentication bank_encryption].each do |slot|
        key = OpenSSL::PKey::RSA.generate(2048)
        version = slot == :bank_authentication ? Epics::Signature::X_VERSION_2 : Epics::Signature::E_VERSION_2
        sig = Epics::Signature.new(version, Epics::SignatureAlgorithm::RsaPkcs1.new(key))
        sig.certificate = Epics::Crypt::X509.new(generate_x_509_crt(key, dn))
        client.keyring.send(:"#{slot}=", sig)
      end
    end

    it 'preserves bank certificates through dump/reload cycle' do
      original_auth_fp = client.keyring.bank_authentication.certificate.fingerprint
      original_enc_fp = client.keyring.bank_encryption.certificate.fingerprint

      json = client.send(:dump_keys)
      reloaded = Epics::Client.new(json, passphrase, 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01',
                                   version: Epics::Keyring::VERSION_30)

      expect(reloaded.keyring.bank_authentication.certificate).not_to be_nil
      expect(reloaded.keyring.bank_encryption.certificate).not_to be_nil
      expect(reloaded.keyring.bank_authentication.certificate.fingerprint).to eq(original_auth_fp)
      expect(reloaded.keyring.bank_encryption.certificate.fingerprint).to eq(original_enc_fp)
    end

    it 'uses certificate-based digest after reload' do
      resolver = Epics::Services::DigestResolver::V3.new
      original_digest = resolver.sign_digest(client.keyring.bank_authentication)

      json = client.send(:dump_keys)
      reloaded = Epics::Client.new(json, passphrase, 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01',
                                   version: Epics::Keyring::VERSION_30)

      reloaded_digest = resolver.sign_digest(reloaded.keyring.bank_authentication)
      expect(reloaded_digest).to eq(original_digest)
    end

    it 'dump_keys includes cert data for bank keys with certificates' do
      json = client.send(:dump_keys)
      parsed = JSON.parse(json)

      bank_auth = parsed['HOST01.X002']
      bank_enc = parsed['HOST01.E002']

      expect(bank_auth).to be_a(Hash)
      expect(bank_auth).to have_key('key')
      expect(bank_auth).to have_key('cert')
      expect(bank_enc).to be_a(Hash)
      expect(bank_enc).to have_key('key')
      expect(bank_enc).to have_key('cert')
    end

    it 'dump_keys uses plain string for bank keys without certificates' do
      # Remove certificates
      client.keyring.bank_authentication.certificate = nil
      client.keyring.bank_encryption.certificate = nil

      json = client.send(:dump_keys)
      parsed = JSON.parse(json)

      expect(parsed['HOST01.X002']).to be_a(String)
      expect(parsed['HOST01.E002']).to be_a(String)
    end

    it 'backward compatible: loads legacy format without certificates' do
      # Remove certificates and save in old format (plain strings)
      client.keyring.bank_authentication.certificate = nil
      client.keyring.bank_encryption.certificate = nil

      json = client.send(:dump_keys)
      reloaded = Epics::Client.new(json, passphrase, 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01',
                                   version: Epics::Keyring::VERSION_30)

      expect(reloaded.keyring.bank_authentication.certificate).to be_nil
      expect(reloaded.keyring.bank_encryption.certificate).to be_nil
      expect(reloaded.keyring.bank_authentication.key).not_to be_nil
      expect(reloaded.keyring.bank_encryption.key).not_to be_nil
    end
  end

  describe 'Client.setup key generation' do
    it 'generates A006 user signature by default' do
      client = Epics::Client.setup('pass', 'https://example.com', 'H', 'U', 'P', 2048)
      expect(client.keyring.user_signature.version).to eq('A006')
    end

    it 'can generate A005 user signature via option' do
      client = Epics::Client.setup('pass', 'https://example.com', 'H', 'U', 'P', 2048, signature_version: Epics::Signature::A_VERSION_5)
      expect(client.keyring.user_signature.version).to eq('A005')
    end

    it 'generates X002 user authentication' do
      client = Epics::Client.setup('pass', 'https://example.com', 'H', 'U', 'P', 2048)
      expect(client.keyring.user_authentication.version).to eq('X002')
    end

    it 'generates E002 user encryption' do
      client = Epics::Client.setup('pass', 'https://example.com', 'H', 'U', 'P', 2048)
      expect(client.keyring.user_encryption.version).to eq('E002')
    end

    it 'uses RsaPss for A006 and RsaPkcs1 for X002/E002' do
      client = Epics::Client.setup('pass', 'https://example.com', 'H', 'U', 'P', 2048)
      expect(client.keyring.user_signature.key).to be_a(Epics::SignatureAlgorithm::RsaPss)
      expect(client.keyring.user_authentication.key).to be_a(Epics::SignatureAlgorithm::RsaPkcs1)
      expect(client.keyring.user_encryption.key).to be_a(Epics::SignatureAlgorithm::RsaPkcs1)
    end

    it 'defaults to H004 version' do
      client = Epics::Client.setup('pass', 'https://example.com', 'H', 'U', 'P', 2048)
      expect(client.version).to eq('H004')
    end

    it 'accepts version option' do
      client = Epics::Client.setup('pass', 'https://example.com', 'H', 'U', 'P', 2048, version: Epics::Keyring::VERSION_30)
      expect(client.version).to eq('H005')
    end
  end

  describe 'Client#next_order_id' do
    let(:client) do
      Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret',
                        'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS')
    end

    it 'increments on each call' do
      first = client.next_order_id
      second = client.next_order_id
      expect(second).to eq(first + 1)
    end

    it 'raises on overflow (>= 1679615)' do
      client.current_order_id = 1_679_615
      expect { client.next_order_id }.to raise_error(RuntimeError, /overflow/)
    end

    it 'can be set via options' do
      client2 = Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret',
                                  'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', order_id: 100)
      expect(client2.next_order_id).to eq(101)
    end
  end

  describe 'Client key extraction from fixture' do
    let(:client) do
      Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret',
                        'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS')
    end

    it 'extracts all 5 key slots' do
      expect(client.keyring.user_signature).not_to be_nil
      expect(client.keyring.user_authentication).not_to be_nil
      expect(client.keyring.user_encryption).not_to be_nil
      expect(client.keyring.bank_authentication).not_to be_nil
      expect(client.keyring.bank_encryption).not_to be_nil
    end

    it 'assigns correct types' do
      expect(client.keyring.user_signature.type).to eq('A')
      expect(client.keyring.user_authentication.type).to eq('X')
      expect(client.keyring.user_encryption.type).to eq('E')
      expect(client.keyring.bank_authentication.type).to eq('X')
      expect(client.keyring.bank_encryption.type).to eq('E')
    end

    it 'bank keys are prefixed with host_id in keys hash' do
      keys = client.keys
      expect(keys).to have_key('SIZBN001.X002')
      expect(keys).to have_key('SIZBN001.E002')
    end
  end

  describe 'Client#version and #urn_schema' do
    it 'returns H003 URN for VERSION_24' do
      client = Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret',
                                 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version: Epics::Keyring::VERSION_24)
      expect(client.version).to eq('H003')
      expect(client.urn_schema).to eq('http://www.ebics.org/H003')
    end

    it 'returns H004 URN for VERSION_25' do
      client = Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret',
                                 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version: Epics::Keyring::VERSION_25)
      expect(client.version).to eq('H004')
      expect(client.urn_schema).to eq('urn:org:ebics:H004')
    end

    it 'returns H005 URN for VERSION_30' do
      client = Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret',
                                 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version: Epics::Keyring::VERSION_30)
      expect(client.version).to eq('H005')
      expect(client.urn_schema).to eq('urn:org:ebics:H005')
    end
  end
end

RSpec.describe 'X.509 certificate handling' do
  let(:url) { 'https://example.com/ebics' }
  let(:passphrase) { 'secret' }

  def setup_client(**options)
    Epics::Client.setup(passphrase, url, 'HOST01', 'USER01', 'PARTNER01', 1024, **options)
  end

  def foreign_certificate
    key = OpenSSL::PKey::RSA.generate(1024)
    Epics::Crypt::X509.new(generate_x_509_crt(key, '/C=GB/O=Other/CN=other.example.org'))
  end

  describe 'Client.setup on H005' do
    subject(:client) { setup_client(version: Epics::Keyring::VERSION_30) }

    it 'generates a certificate for every user key' do
      certificates = [client.keyring.user_signature, client.keyring.user_authentication,
                      client.keyring.user_encryption].map(&:certificate)

      expect(certificates).to all(be_a(Epics::Crypt::X509))
    end

    it 'generates certificates that match their key' do
      signature = client.keyring.user_signature

      expect(signature.certificate.certificate.public_key.to_pem)
        .to eq(signature.key.key.public_key.to_pem)
    end

    it 'names the subject after the client identity' do
      expect(client.keyring.user_signature.certificate.certificate.subject.to_s)
        .to include('CN=USER01', 'OU=PARTNER01', 'O=HOST01')
    end

    it 'accepts a custom subject' do
      client = setup_client(version: Epics::Keyring::VERSION_30, certificate_subject: '/CN=Custom/O=Acme/C=CH')

      expect(client.keyring.user_signature.certificate.certificate.subject.to_s).to include('CN=Custom')
    end

    it 'accepts a custom validity' do
      not_after = Time.utc(2030, 1, 1)
      client = setup_client(version: Epics::Keyring::VERSION_30, certificate_not_after: not_after)

      expect(client.keyring.user_signature.certificate.certificate.not_after).to eq(not_after)
    end

    it 'keeps a supplied certificate instead of generating one' do
      supplied = foreign_certificate
      client = setup_client(version: Epics::Keyring::VERSION_30,
                            x_509_certificate_a_content: supplied.to_pem)

      expect(client.keyring.user_signature.certificate.fingerprint).to eq(supplied.fingerprint)
      expect(client.keyring.user_authentication.certificate).not_to be_nil
    end

    it 'can be turned off' do
      client = setup_client(version: Epics::Keyring::VERSION_30, generate_certificates: false)

      expect(client.keyring.user_signature.certificate).to be_nil
    end

    it 'does not mutate the options hash it was given' do
      options = { version: Epics::Keyring::VERSION_30, signature_version: Epics::Signature::A_VERSION_5 }
      Epics::Client.setup(passphrase, url, 'HOST01', 'USER01', 'PARTNER01', 1024, options)

      expect(options).to include(signature_version: Epics::Signature::A_VERSION_5)
    end
  end

  describe 'Client.setup on H004' do
    subject(:client) { setup_client }

    it 'generates no certificates' do
      expect(client.keyring.user_signature.certificate).to be_nil
    end

    it 'still accepts them explicitly' do
      client = setup_client(generate_certificates: true)

      expect(client.keyring.user_signature.certificate).to be_a(Epics::Crypt::X509)
    end
  end

  describe 'persistence' do
    let(:client) { setup_client(version: Epics::Keyring::VERSION_30) }

    def reload(json, **options)
      Epics::Client.new(json, passphrase, url, 'HOST01', 'USER01', 'PARTNER01',
                        version: Epics::Keyring::VERSION_30, **options)
    end

    it 'restores user certificates from a key file' do
      fingerprints = %i[user_signature user_authentication user_encryption]
                     .map { |slot| client.keyring.send(slot).certificate.fingerprint }
      reloaded = reload(client.send(:dump_keys))

      expect(%i[user_signature user_authentication user_encryption]
               .map { |slot| reloaded.keyring.send(slot).certificate.fingerprint }).to eq(fingerprints)
    end

    it 'keeps a restored certificate when no option is passed' do
      reloaded = reload(client.send(:dump_keys))

      expect(reloaded.keyring.user_signature.certificate).not_to be_nil
    end

    it 'lets an explicit option override a restored certificate' do
      supplied = foreign_certificate
      reloaded = reload(client.send(:dump_keys), x_509_certificate_a_content: supplied.to_pem)

      expect(reloaded.keyring.user_signature.certificate.fingerprint).to eq(supplied.fingerprint)
    end

    it 'keeps the bare form for keys without a certificate' do
      h004 = setup_client
      dumped = JSON.parse(h004.send(:dump_keys))

      expect(dumped.values).to all(be_a(String))
    end
  end

  describe 'invalid certificate content' do
    it 'raises and names the option' do
      expect do
        setup_client(version: Epics::Keyring::VERSION_30, x_509_certificate_a_content: 'not-a-pem')
      end.to raise_error(Epics::InvalidCertificateError, /x_509_certificate_a_content/)
    end

    it 'ignores empty content' do
      client = setup_client(version: Epics::Keyring::VERSION_30, x_509_certificate_x_content: '')

      expect(client.keyring.user_authentication.certificate).to be_a(Epics::Crypt::X509)
    end
  end

  # H005 carries the public key inside ds:X509Data, so a request built without a
  # certificate would contain no key material at all.
  describe 'H005 key management without certificates', without_certificates: true do
    let(:client) do
      setup_client(version: Epics::Keyring::VERSION_30, generate_certificates: false)
    end

    it 'refuses to build INI' do
      expect { Epics::INI.new(client).key_signature }
        .to raise_error(Epics::MissingCertificateError, /x_509_certificate_a_content/)
    end

    it 'refuses to build HIA' do
      expect { Epics::HIA.new(client).order_data }
        .to raise_error(Epics::MissingCertificateError, /x_509_certificate_x_content/)
    end
  end

  describe 'H005 key management with certificates' do
    let(:client) { setup_client(version: Epics::Keyring::VERSION_30) }

    it 'carries the certificate in INI order data' do
      expect(Epics::INI.new(client).key_signature)
        .to include("<ds:X509Certificate>#{client.keyring.user_signature.certificate.data}</ds:X509Certificate>")
    end

    it 'carries both certificates in HIA order data' do
      order_data = Epics::HIA.new(client).order_data

      expect(order_data).to include(client.keyring.user_authentication.certificate.data)
      expect(order_data).to include(client.keyring.user_encryption.certificate.data)
    end

    it 'validates INI order data against the S002 schema' do
      schema = Nokogiri::XML::Schema(File.open(File.join(File.dirname(__FILE__), 'xsd', 'H005',
                                                         'ebics_signature_S002.xsd')))

      expect(schema.validate(Nokogiri::XML(Epics::INI.new(client).key_signature))).to be_empty
    end
  end

  describe 'H004 key management' do
    let(:client) { setup_client }

    it 'still sends the raw modulus and exponent' do
      order_data = Epics::INI.new(client).key_signature

      expect(order_data).to include('Modulus')
      expect(order_data).not_to include('X509Data')
    end
  end
end

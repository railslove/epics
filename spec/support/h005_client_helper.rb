RSpec.configure do |config|
  config.before(:each) do
    next unless defined?(client) && client.is_a?(Epics::Client) && client.version == Epics::Keyring::VERSION_30

    dn = '/C=DE/O=TestBank/CN=test.ebics.org'
    [client.keyring.user_signature, client.keyring.user_authentication, client.keyring.user_encryption,
     client.keyring.bank_authentication, client.keyring.bank_encryption].each do |sig|
      next unless sig && sig.certificate.nil?

      key = sig.key.key
      key = OpenSSL::PKey::RSA.generate(2048) unless key.private?
      sig.certificate = Epics::Crypt::X509.new(generate_x_509_crt(key, dn))
    end
  end
end

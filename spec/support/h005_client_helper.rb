# Almost every H005 request needs certificates, so they are injected into any `client`
# let rather than set up in each spec. Tag an example or group
# `without_certificates: true` to exercise the path where none are configured.
RSpec.configure do |config|
  # Bank signatures hold a public key only, so a throwaway pair stands in. Generated
  # once -- per-example generation dominated the suite runtime.
  throwaway_key = OpenSSL::PKey::RSA.generate(2048)
  dn = '/C=DE/O=TestBank/CN=test.ebics.org'

  config.before(:each) do |example|
    next if example.metadata[:without_certificates]
    next unless defined?(client) && client.is_a?(Epics::Client) && client.version == Epics::Keyring::VERSION_30

    [client.keyring.user_signature, client.keyring.user_authentication, client.keyring.user_encryption,
     client.keyring.bank_authentication, client.keyring.bank_encryption].each do |sig|
      next unless sig && sig.certificate.nil?

      key = sig.key.key
      key = throwaway_key unless key.private?
      sig.certificate = Epics::Crypt::X509.new(generate_x_509_crt(key, dn))
    end
  end
end

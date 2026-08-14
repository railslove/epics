class Epics::Crypt::X509
  extend Forwardable

  # Swiss market practice guidelines §6.1 name 9999-12-31 as the "unlimited" validity
  # date. An expired certificate means re-initialising with the bank.
  UNLIMITED = Time.utc(9999, 12, 31, 23, 59, 59).freeze

  KEY_USAGE = 'digitalSignature,nonRepudiation,keyEncipherment'.freeze

  attr_reader :certificate

  def_delegators :certificate, :issuer, :serial, :version, :to_der, :to_pem

  # Self-signed certificate for `key`, which may be an OpenSSL::PKey::RSA or an
  # Epics::SignatureAlgorithm wrapping one. `subject` takes an OpenSSL::X509::Name or
  # any string OpenSSL::X509::Name.parse accepts.
  def self.generate(key, subject:, not_before: nil, not_after: UNLIMITED, serial: nil)
    key = key.key if key.respond_to?(:key)
    name = subject.is_a?(OpenSSL::X509::Name) ? subject : OpenSSL::X509::Name.parse(subject)

    certificate = OpenSSL::X509::Certificate.new
    certificate.version = 2
    certificate.serial = serial || SecureRandom.random_number(2**64)
    certificate.subject = name
    certificate.issuer = name
    certificate.public_key = key.public_key
    certificate.not_before = not_before || Time.now.utc
    certificate.not_after = not_after

    factory = OpenSSL::X509::ExtensionFactory.new
    factory.subject_certificate = certificate
    factory.issuer_certificate = certificate
    certificate.add_extension(factory.create_extension('basicConstraints', 'CA:FALSE', true))
    certificate.add_extension(factory.create_extension('keyUsage', KEY_USAGE, true))

    certificate.sign(key, OpenSSL::Digest.new('SHA256'))

    new(certificate.to_pem)
  end

  def initialize(content)
    @certificate = OpenSSL::X509::Certificate.new(content)
  end

  def data
    Base64.strict_encode64(certificate.to_der)
  end

  def fingerprint
    Digest::SHA256.hexdigest(certificate.to_der).upcase
  end
end

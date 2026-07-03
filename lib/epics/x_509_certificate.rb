class Epics::X509Certificate
  extend Forwardable

  attr_reader :certificate

  def_delegators :certificate, :issuer, :version, :serial

  def initialize(crt_content)
    @certificate =
      if crt_content.is_a?(OpenSSL::X509::Certificate)
        crt_content
      else
        OpenSSL::X509::Certificate.new(crt_content)
      end
  end

  def data
    Base64.strict_encode64(@certificate.to_der)
  end

  # SHA-256 fingerprint of the DER-encoded certificate (upper-case hex), as
  # printed on the EBICS 3.0 INI letter.
  def fingerprint
    Digest::SHA256.hexdigest(@certificate.to_der).upcase
  end

  # Generates a self-signed X.509 certificate wrapping the given RSA key. EBICS
  # 3.0 (H005) requires every public key to be transmitted as an X.509
  # certificate; for banks using the shared-key model (e.g. German banks) a
  # self-signed certificate is sufficient.
  def self.generate_self_signed(rsa_key, subject:, valid_years: 10)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = OpenSSL::BN.new(Digest::SHA256.hexdigest(rsa_key.n.to_s(16))[0, 16].to_i(16))
    name = OpenSSL::X509::Name.parse(subject)
    cert.subject = name
    cert.issuer = name
    cert.public_key = rsa_key.public_key
    cert.not_before = Time.now
    cert.not_after = Time.now + (valid_years * 365 * 24 * 60 * 60)
    cert.sign(rsa_key, OpenSSL::Digest::SHA256.new)

    new(cert)
  end
end

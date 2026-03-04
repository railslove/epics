class Epics::Crypt::X509
  extend Forwardable

  attr_reader :certificate

  def_delegators :certificate, :issuer, :version, :to_der, :to_pem

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
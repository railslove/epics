class Epics::X509Certificate
  extend Forwardable

  attr_reader :certificate

  def_delegators :certificate, :issuer, :version

  def initialize(crt_content)
    @certificate = OpenSSL::X509::Certificate.new(crt_content)
  end

  def data
    Base64.strict_encode64(@certificate.to_der)
  end
end
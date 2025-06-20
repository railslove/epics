class Epics::Crypt::X509
  extend Forwardable

  attr_reader :certificate

  def_delegators :certificate, :issuer, :version, :to_der

  def initialize(content)
    @certificate = OpenSSL::X509::Certificate.new(content)
  end
end
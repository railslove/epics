class Epics::Handlers::OrderDataHandler::V3 < Epics::Handlers::OrderDataHandler::Base
  protected

  def h00x_version
    'H005'
  end

  def h00x_namespace
    'urn:org:ebics:H005'
  end

  def create_signature_pubbey_order_data(&block)
    super do
      namespaces = { xmlns: 'http://www.ebics.org/S002' }
      namespaces['xmlns:ds'] = 'http://www.w3.org/2000/09/xmldsig#'
      @xml.SignaturePubKeyOrderData(**namespaces, &block)
    end
  end

  # H005 has no raw modulus/exponent form: the key travels inside the ds:X509Data that
  # handle_x509_data emits. Without a certificate the element carries no key at all.
  def handle_ini_signature_pubkey(signature, _timestamp)
    require_certificate!(signature, Epics::Signature::TYPE_A)
  end

  def handle_hia_authentication_pubkey(authentication, _timestamp)
    require_certificate!(authentication, Epics::Signature::TYPE_X)
  end

  def handle_hia_encryption_pubkey(encryption, _timestamp)
    require_certificate!(encryption, Epics::Signature::TYPE_E)
  end

  private

  def require_certificate!(signature, type)
    return if signature.certificate

    raise Epics::MissingCertificateError.new(signature.version, Epics::Client::CERTIFICATE_OPTIONS[type])
  end
end

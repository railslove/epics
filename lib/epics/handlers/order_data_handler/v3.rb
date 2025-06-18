class Epics::Handlers::OrderDataHandler::V3 < Epics::Handlers::OrderDataHandler::Base
  protected

  def h00x_version
    'H005'
  end

  def h00x_namespace
    'urn:org:ebics:H005'
  end

  def create_signature_pubbey_order_data
    super do
      namespaces = { xmlns: 'http://www.ebics.org/S002' }
      namespaces['xmlns:ds'] = 'http://www.w3.org/2000/09/xmldsig#'
      @xml.SignaturePubKeyOrderData **namespaces do
        yield
      end
    end
  end

  def handle_ini_signature_pubkey(signature, timestamp)
  end

  def handle_hia_authentication_pubkey(authentication, timestamp)
  end

  def handle_hia_encryption_pubkey(encryption, timestamp)
  end
end

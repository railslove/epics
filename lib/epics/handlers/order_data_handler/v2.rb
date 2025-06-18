class Epics::Handlers::OrderDataHandler::V2 < Epics::Handlers::OrderDataHandler::Base
  protected

  def create_signature_pubbey_order_data
    super do
      namespaces = { xmlns: 'http://www.ebics.org/S001' }
      namespaces['xmlns:ds'] = 'http://www.w3.org/2000/09/xmldsig#'
      @xml.SignaturePubKeyOrderData **namespaces do
        yield
      end
    end
  end

  def handle_ini_signature_pubkey(signature, timestamp)
    handle_pubkey_value(signature, timestamp)
  end

  def handle_hia_authentication_pubkey(authentication, timestamp)
    handle_pubkey_value(authentication, timestamp)
  end

  def handle_hia_encryption_pubkey(encryption, timestamp)
    handle_pubkey_value(encryption, timestamp)
  end

  private

  def handle_pubkey_value(signature, timestamp)
    modulus = [signature.key.modulus.to_s(16)].pack('H*')
    exponent = signature.key.exponent.to_s(2)
    @xml.PubKeyValue do
      @xml.send('ds:RSAKeyValue') do
        @xml.send('ds:Modulus', Base64.strict_encode64(modulus))
        @xml.send('ds:Exponent', Base64.strict_encode64(exponent))
      end
      @xml.TimeStamp timestamp.iso8601
    end
  end
end

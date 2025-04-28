class Epics::Handlers::OrderDataHandler::Base
  def initialize(client)
    @client = client
  end

  def handle_ini(signature, timestamp = Time.now.utc)
    create_signature_pubbey_order_data do
      @xml.SignaturePubKeyInfo do
        handle_ini_signature_pubkey(signature, timestamp)
        @xml.SignatureVersion signature.version
      end
      handle_partner_id
      handle_user_id
    end
  end

  def handle_hia(authentication, encryption, timestamp = Time.now.utc)
    create_hia_request_order_data do
      @xml.AuthenticationPubKeyInfo do
        handle_hia_authentication_pubkey(authentication, timestamp)
        @xml.AuthenticationVersion authentication.version
      end
      @xml.EncryptionPubKeyInfo do
        handle_hia_encryption_pubkey(encryption, timestamp)
        @xml.EncryptionVersion encryption.version
      end
      handle_partner_id
      handle_user_id
    end
  end

  def to_xml
    @xml.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end

  protected

  def create_signature_pubbey_order_data
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      yield
    end
  end

  def create_hia_request_order_data
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      namespaces = { xmlns: h00x_namespace }
      namespaces['xmlns:ds'] = 'http://www.w3.org/2000/09/xmldsig#'
      @xml.HIARequestOrderData **namespaces do
        yield
      end
    end
  end

  def handle_ini_signature_pubkey(signature, timestamp)
    raise NotImplementedError
  end

  def handle_hia_authentication_pubkey(authentication, timestamp)
    raise NotImplementedError
  end

  def handle_hia_encryption_pubkey(encryption, timestamp)
    raise NotImplementedError
  end

  def h00x_version
    raise NotImplementedError
  end

  def h00x_namespace
    raise NotImplementedError
  end

  private

  def handle_partner_id
    @xml.PartnerID @client.partner_id
  end

  def handle_user_id
    @xml.UserID @client.user_id
  end
end

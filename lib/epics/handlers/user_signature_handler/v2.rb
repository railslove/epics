class Epics::Handlers::UserSignatureHandler::V2 < Epics::Handlers::UserSignatureHandler::Base
  def handle(digest)
    canonicalized_user_signature_data_hash_signed = @crypt_service.encrypt(@client.keyring.user_signature, digest)

    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      xml.UserSignatureData('xmlns' => 'http://www.ebics.org/S001', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:schemaLocation' => 'http://www.ebics.org/S001 http://www.ebics.org/S001/ebics_signature.xsd') do
        xml.OrderSignatureData do
          xml.SignatureVersion @client.keyring.user_signature.version
          xml.SignatureValue Base64.strict_encode64(canonicalized_user_signature_data_hash_signed)
          xml.PartnerID @client.partner_id
          xml.UserID @client.user_id
        end
      end
    end
  end
end
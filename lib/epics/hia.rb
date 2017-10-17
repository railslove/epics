class Epics::HIA < Epics::GenericRequest
  def root
    "ebicsUnsecuredRequest"
  end

  def header
    Nokogiri::XML::Builder.new do |xml|
      xml.header(authenticate: true) {
        xml.static {
          xml.HostID host_id
          xml.PartnerID partner_id
          xml.UserID user_id
          xml.Product("EPICS - a ruby ebics kernel", 'Language' => 'de')
          xml.OrderDetails {
            xml.OrderType 'HIA'
            xml.OrderAttribute 'DZNNN'
          }
          xml.SecurityMedium '0000'
        }
        xml.mutable ''
      }
    end.doc.root
  end

  def body
    Nokogiri::XML::Builder.new do |xml|
      xml.body{
        xml.DataTransfer {
          xml.OrderData Base64.strict_encode64(Zlib::Deflate.deflate(order_data))
        }
      }
    end.doc.root
  end

  def order_data
    Nokogiri::XML::Builder.new do |xml|
      xml.HIARequestOrderData('xmlns:ds': 'http://www.w3.org/2000/09/xmldsig#', xmlns: 'urn:org:ebics:H004') {
        xml.AuthenticationPubKeyInfo {
          xml.PubKeyValue {
            xml.send('ds:RSAKeyValue') {
              xml.send('ds:Modulus', Base64.strict_encode64([client.x.n].pack("H*")))
              xml.send('ds:Exponent', Base64.strict_encode64(client.x.key.e.to_s(2)))
            }
          }
          xml.AuthenticationVersion 'X002'
        }
        xml.EncryptionPubKeyInfo{
          xml.PubKeyValue {
            xml.send('ds:RSAKeyValue') {
              xml.send('ds:Modulus', Base64.strict_encode64([client.e.n].pack("H*")))
              xml.send('ds:Exponent', Base64.strict_encode64(client.e.key.e.to_s(2)))
            }
          }
          xml.EncryptionVersion 'E002'
        }
        xml.PartnerID partner_id
        xml.UserID user_id
      }
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end

  def to_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.send(root, 'xmlns:ds': 'http://www.w3.org/2000/09/xmldsig#', xmlns: 'urn:org:ebics:H004', Version: 'H004', Revision: '1') {
        xml.parent.add_child(header)
        xml.parent.add_child(body)
      }
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end
end

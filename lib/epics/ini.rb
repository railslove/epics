class Epics::INI < Epics::GenericRequest
  def root
    "ebicsUnsecuredRequest"
  end

  def header
    client.header_request.build(
      order_type: 'INI',
      order_attribute: 'DZNNN',
      with_bank_pubkey_digests: false,
      mutable: {},
    )
  end

  def body
    Nokogiri::XML::Builder.new do |xml|
      xml.body{
        xml.DataTransfer {
          xml.OrderData Base64.strict_encode64(Zlib::Deflate.deflate(key_signature))
        }
      }
    end.doc.root
  end

  def key_signature
    Nokogiri::XML::Builder.new do |xml|
      xml.SignaturePubKeyOrderData('xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => 'http://www.ebics.org/S001') {
        xml.SignaturePubKeyInfo {
          x509_data_xml(xml, client.x_509_certificate(:a))
          xml.PubKeyValue {
            xml.send('ds:RSAKeyValue') {
              xml.send('ds:Modulus', Base64.strict_encode64([client.a.n].pack("H*")))
              xml.send('ds:Exponent', Base64.strict_encode64(client.a.key.e.to_s(2)))
            }
            xml.TimeStamp timestamp
          }
          xml.SignatureVersion 'A006'
        }
        xml.PartnerID partner_id
        xml.UserID user_id
      }
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end

  def to_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.send(root, 'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => 'urn:org:ebics:H004', 'Version' => 'H004', 'Revision' => '1') {
        xml.parent.add_child(header)
        xml.parent.add_child(body)
      }
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end
end

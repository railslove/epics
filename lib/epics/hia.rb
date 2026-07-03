class Epics::HIA < Epics::GenericRequest
  def root
    "ebicsUnsecuredRequest"
  end

  def header
    client.header_request.build(
      order_type: 'HIA',
      admin_order_type: 'HIA',
      order_attribute: 'DZNNN',
      with_bank_pubkey_digests: false,
      with_order_params: false,
      mutable: {}
    )
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
    return h005_order_data if client.h005?

    Nokogiri::XML::Builder.new do |xml|
      xml.HIARequestOrderData('xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => client.namespace) {
        xml.AuthenticationPubKeyInfo {
          x509_data_xml(xml, client.x_509_certificate(:x))
          xml.PubKeyValue {
            xml.send('ds:RSAKeyValue') {
              xml.send('ds:Modulus', Base64.strict_encode64([client.x.n].pack("H*")))
              xml.send('ds:Exponent', Base64.strict_encode64(client.x.key.e.to_s(2)))
            }
          }
          xml.AuthenticationVersion 'X002'
        }
        xml.EncryptionPubKeyInfo{
          x509_data_xml(xml, client.x_509_certificate(:e))
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

  # EBICS 3.0 (H005): public keys are carried exclusively as X.509 certificates
  # (ds:X509Data); the H004 RSAKeyValue is no longer part of the structure.
  def h005_order_data
    Nokogiri::XML::Builder.new do |xml|
      xml.HIARequestOrderData('xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => client.namespace) {
        xml.AuthenticationPubKeyInfo {
          x509_data_xml(xml, client.x_509_certificate(:x))
          xml.AuthenticationVersion 'X002'
        }
        xml.EncryptionPubKeyInfo {
          x509_data_xml(xml, client.x_509_certificate(:e))
          xml.EncryptionVersion 'E002'
        }
        xml.PartnerID partner_id
        xml.UserID user_id
      }
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end

  def to_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.send(root, root_attributes) {
        xml.parent.add_child(header)
        xml.parent.add_child(body)
      }
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end
end

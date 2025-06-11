class Epics::HIA < Epics::GenericRequest
  def root
    "ebicsUnsecuredRequest"
  end

  def header
    client.header_request.build(
      order_type: 'HIA',
      order_attribute: 'DZNNN',
      with_bank_pubkey_digests: false,
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
    x_509_certificate_x = client.x_509_certificate(:x)
    x_509_certificate_e = client.x_509_certificate(:e)

    Nokogiri::XML::Builder.new do |xml|
      xml.HIARequestOrderData('xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => 'urn:org:ebics:H004') {
        xml.AuthenticationPubKeyInfo {
          if x_509_certificate_x
            xml.send('ds:X509Data') do
              xml.send('ds:X509IssuerSerial') do
                xml.send('ds:X509IssuerName', x_509_certificate_x.issuer )
                xml.send('ds:X509SerialNumber', x_509_certificate_x.version)
              end
              xml.send('ds:X509Certificate', x_509_certificate_x.data)
            end
          end
          xml.PubKeyValue {
            xml.send('ds:RSAKeyValue') {
              xml.send('ds:Modulus', Base64.strict_encode64([client.x.n].pack("H*")))
              xml.send('ds:Exponent', Base64.strict_encode64(client.x.key.e.to_s(2)))
            }
          }
          xml.AuthenticationVersion 'X002'
        }
        xml.EncryptionPubKeyInfo{
          if x_509_certificate_e
            xml.send('ds:X509Data') do
              xml.send('ds:X509IssuerSerial') do
                xml.send('ds:X509IssuerName', x_509_certificate_e.issuer )
                xml.send('ds:X509SerialNumber', x_509_certificate_e.version)
              end
              xml.send('ds:X509Certificate', x_509_certificate_e.data)
            end
          end
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
      xml.send(root, 'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => 'urn:org:ebics:H004', 'Version' => 'H004', 'Revision' => '1') {
        xml.parent.add_child(header)
        xml.parent.add_child(body)
      }
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end
end

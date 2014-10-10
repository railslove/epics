class Epics::HIA < Epics::GenericRequest

  def root
    "ebicsUnsecuredRequest"
  end

  def header
    {
      :@authenticate => true,
      static: {
        "HostID" => host_id,
        "PartnerID" => partner_id,
        "UserID" => user_id,
        "Product" => {
          :@Language => "de",
          :content! => "EPICS - a ruby ebics kernel"
        },
        "OrderDetails" => {
          "OrderType" => "HIA",
          "OrderAttribute" => "DZNNN"
        },
        "SecurityMedium" => "0000"
     },
      "mutable" => ""
    }
  end

  def body
    {
      "DataTransfer" => {
        "OrderData" => Base64.strict_encode64(Zlib::Deflate.new.deflate(order_data, Zlib::FINISH))
      }
    }
  end

  def order_data
    "<?xml version='1.0' encoding='utf-8'?>\n"+
    Gyoku.xml("HIARequestOrderData" => {
      :"@xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
      :"@xmlns" => "urn:org:ebics:H004",
      "AuthenticationPubKeyInfo" => {
        "PubKeyValue" => {
          "ds:RSAKeyValue" => {
            "ds:Modulus" => Base64.strict_encode64([client.x.n].pack("H*")),
            "ds:Exponent" => Base64.strict_encode64(client.x.key.e.to_s(2))
          }
        },
        "AuthenticationVersion" => "X002"
      },
      "EncryptionPubKeyInfo" => {
        "PubKeyValue" => {
          "ds:RSAKeyValue" => {
            "ds:Modulus" => Base64.strict_encode64([client.e.n].pack("H*")),
            "ds:Exponent" => Base64.strict_encode64(client.e.key.e.to_s(2))
          }
        },
        "EncryptionVersion" => "E002"
      },

      "PartnerID" => partner_id,
      "UserID" => user_id
    })
  end

  def to_xml
    Nokogiri::XML.parse(Gyoku.xml(    {
      root => {
        :"@xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
        :@xmlns => "urn:org:ebics:H004",
        :@Version => "H004",
        :@Revision => "1",
        :header => header,
        "body" => body
      }
    }), nil, "utf-8").to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
  end

end

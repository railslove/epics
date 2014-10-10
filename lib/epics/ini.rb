class Epics::INI < Epics::GenericRequest

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
          "OrderType" => "INI",
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
        "OrderData" => Base64.strict_encode64(Zlib::Deflate.new.deflate(key_signature, Zlib::FINISH))
      }
    }
  end

  def key_signature
    "<?xml version='1.0' encoding='utf-8'?>\n"+
    Gyoku.xml("SignaturePubKeyOrderData" => {
      :"@xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
      :"@xmlns" => "http://www.ebics.org/S001",
      "SignaturePubKeyInfo" => {
        "PubKeyValue" => {
          "ds:RSAKeyValue" => {
            "ds:Modulus" => Base64.strict_encode64([client.a.n].pack("H*")),
            "ds:Exponent" => Base64.strict_encode64(client.a.key.e.to_s(2))
          },
          "TimeStamp" => timestamp
        },
        "SignatureVersion" => "A006"
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

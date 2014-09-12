class Epics::HPB #< Epics::GenericMessage

  def nonce
    SecureRandom.hex(16)
  end

  def timestamp
    Time.now.utc.iso8601
  end

  def host
    "HOST"
  end

  def partner
    "PARTNER"
  end

  def user
    "USER"
  end

  def to_xml
    Nokogiri::XML.parse(Gyoku.xml(
          "?xml/" => {
            :@version => "1.0",
            :@encoding => "utf-8"
          },
          ebics_no_pub_key_digests_request: {
            :"@xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
            :@xmlns => "urn:org:ebics:H004",
            :@Version => "H004",
            :@Revision => "1",
            header: {
              :@authenticate => true,
              static: {
                "HostID" => host,
                "Nonce" => nonce,
                "Timestamp" => timestamp,
                "PartnerID" => partner,
                "UserID" => user,
                "Product" => {
                  :@Language => "de",
                  :content! => "EPICS - a ruby ebics kernel"
                },
                "OrderDetails" => {
                  "OrderType" => "HPB",
                  "OrderAttribute" => "DZHNN"
                },
                "SecurityMedium" => "0000"
              },
              "mutable/" => ""
            },
            "AuthSignature" => {
              "ds:SignedInfo" => {
                "ds:CanonicalizationMethod/" => {
                  :@Algorithm => "http://www.w3.org/TR/2001/REC-xml-c14n-20010315"
                },
                "ds:SignatureMethod/" => {
                  :@Algorithm => "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
                },
                "ds:Reference/" => {
                  :@URI => "#xpointer(//*[@authenticate='true'])",
                  "ds:Transforms" => {
                    "ds:Transform/" => {
                      :@Algorithm => "http://www.w3.org/TR/2001/REC-xml-c14n-20010315"
                    }
                  },
                  "ds:DigestMethod/" => {
                    :@Algorithm => "http://www.w3.org/2001/04/xmlenc#sha256"
                  },
                  "ds:DigestValue/" => ""
                }
              },
              "ds:SignatureValue/" => ""
            },
            "body/" => ""
          },
        )).to_xml
  end
end
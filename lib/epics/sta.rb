class Epics::STA < Epics::GenericRequest
  attr_accessor :from, :to

  def initialize(client, from, to)
    super(client)
    self.from = from
    self.to = to
  end

  def to_xml
    Nokogiri::XML.parse(Gyoku.xml(
          "?xml/" => {
            :@version => "1.0",
            :@encoding => "utf-8"
          },
          "ebicsRequest" => {
            :"@xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
            :"@xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
            :"@xsi:schemaLocation" => "urn:org:ebics:H004 http://www.ebics.org/H004/ebics_response_H004.xsd",
            :@xmlns => "urn:org:ebics:H004",
            :@Version => "H004",
            :@Revision => "1",
            header: {
              :@authenticate => true,
              static: {
                "HostID" => host_id,
                "Nonce" => nonce,
                "Timestamp" => timestamp,
                "PartnerID" => partner_id,
                "UserID" => user_id,
                "Product" => {
                  :@Language => "de",
                  :content! => "EPICS - a ruby ebics kernel"
                },
                "OrderDetails" => {
                  "OrderType" => "STA",
                  "OrderAttribute" => "DZHNN",
                  "StandardOrderParams" => {
                    "DateRange" => {
                      "Start" => from,
                      "End" => to
                    }
                  }
                },
                "BankPubKeyDigests" => {
                  "Authentication" => {
                    :@Version => "X002",
                    :@Algorithm => "http://www.w3.org/2001/04/xmlenc#sha256",
                    :content! => client.bank_x.public_digest
                  },
                  "Encryption" => {
                    :@Version => "E002",
                    :@Algorithm => "http://www.w3.org/2001/04/xmlenc#sha256",
                    :content! => client.bank_e.public_digest
                  }
                },
                "SecurityMedium" => "0000"
             },
              "mutable" => {
                "TransactionPhase" => "Initialisation"
              }
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

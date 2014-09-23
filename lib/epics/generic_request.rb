class Epics::GenericRequest
  extend Forwardable
  attr_accessor :client

  def initialize(client)
    self.client = client
  end

  def nonce
    SecureRandom.hex(16)
  end

  def timestamp
    Time.now.utc.iso8601
  end

  def_delegators :client, :host_id, :user_id, :partner_id

  def root
    "ebicsRequest"
  end

  def body
    ""
  end

  def auth_signature
    {
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
    }
  end

  def to_transfer_xml
    Nokogiri::XML.parse(Gyoku.xml({
      root => {
        :"@xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
        :@xmlns => "urn:org:ebics:H004",
        :@Version => "H004",
        :@Revision => "1",
        "header" => {
          :@authenticate => true,
          "static" => {
            "HostID" => host_id,
            "TransactionID" => transaction_id
          },
          "mutable" => {
            "TransactionPhase" => "Transfer",
            "SegmentNumber" => {
              :@lastSegment => true,
              :content! => 1
            }
          }
        },
        "AuthSignature" => auth_signature,
        "body" => {
          "DataTransfer" => {
            "OrderData" => encrypted_order_data
          }
        }
      }
    }, order!: [:header, :AuthSignature]), nil, "utf-8").to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
  end

  def to_xml
    Nokogiri::XML.parse(Gyoku.xml(    {
      root => {
        :"@xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
        :@xmlns => "urn:org:ebics:H004",
        :@Version => "H004",
        :@Revision => "1",
        :header => header,
        "AuthSignature" => auth_signature,
        "body" => body
      }
    }, order!: [:header, :AuthSignature]), nil, "utf-8").to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
  end


end

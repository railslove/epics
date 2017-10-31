class Epics::GenericRequest
  extend Forwardable
  attr_accessor :client
  attr_accessor :transaction_id

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
    Nokogiri::XML::Builder.new do |xml|
      xml.body
    end.doc.root
  end

  def auth_signature
    Nokogiri::XML::Builder.new do |xml|
      xml.AuthSignature{
        xml.send('ds:SignedInfo') {
          xml.send('ds:CanonicalizationMethod', '', Algorithm: "http://www.w3.org/TR/2001/REC-xml-c14n-20010315")
          xml.send('ds:SignatureMethod', '', Algorithm: "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")
          xml.send('ds:Reference', '', URI: "#xpointer(//*[@authenticate='true'])") {
            xml.send('ds:Transforms') {
              xml.send('ds:Transform', '', Algorithm: "http://www.w3.org/TR/2001/REC-xml-c14n-20010315")
            }
            xml.send('ds:DigestMethod', '', Algorithm: "http://www.w3.org/2001/04/xmlenc#sha256")
            xml.send('ds:DigestValue', '')
          }
        }
        xml.send('ds:SignatureValue', '')
      }
    end.doc.root
  end

  def to_transfer_xml
    [].tap do |data|
      encrypted_order_data_chunks.each_with_index do |chunk, index|
        xml_chunk = Nokogiri::XML::Builder.new do |xml|
          xml.send(root, 'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => 'urn:org:ebics:H004', 'Version' => 'H004', 'Revision' => '1') {
            xml.header(authenticate: true) {
              xml.static {
                xml.HostID host_id
                xml.TransactionID transaction_id
              }
              xml.mutable {
                xml.TransactionPhase 'Transfer'
                if encrypted_order_data_chunks.last == chunk
                  xml.SegmentNumber(index + 1, lastSegment: true)
                else
                  xml.SegmentNumber(index + 1)
                end
              }
            }
            xml.parent.add_child(auth_signature)
            xml.body {
              xml.DataTransfer {
                xml.OrderData chunk
              }
            }
          }
        end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')

        if block_given?
          yield xml_chunk
        else
          data << xml_chunk
        end
      end
    end
  end

  def to_receipt_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.send(root, 'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => 'urn:org:ebics:H004', 'Version' => 'H004', 'Revision' => '1') {
        xml.header(authenticate: true) {
          xml.static {
            xml.HostID host_id
            xml.TransactionID(transaction_id)
          }
          xml.mutable {
            xml.TransactionPhase 'Receipt'
          }
        }
        xml.parent.add_child(auth_signature)
        xml.body {
          xml.TransferReceipt(authenticate: true) {
            xml.ReceiptCode 0
          }
        }
      }
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end

  def to_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.send(root, 'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => 'urn:org:ebics:H004', 'Version' => 'H004', 'Revision'=> '1') {
        xml.parent.add_child(header)
        xml.parent.add_child(auth_signature)
        xml.parent.add_child(body)
      }
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end
end

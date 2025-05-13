class Epics::GenericRequest
  extend Forwardable
  attr_reader :client, :options
  attr_accessor :transaction_id

  def initialize(client, **options)
    @client = client
    @options = options
  end

  def nonce
    SecureRandom.hex(16)
  end

  def timestamp
    Time.now.utc.iso8601
  end

  def_delegators :client, :host_id, :user_id, :partner_id

  def root
    'ebicsRequest'
  end

  def body
    Nokogiri::XML::Builder.new do |xml|
      xml.body
    end.doc.root
  end

  def header
    raise NotImplementedError
  end

  def auth_signature
    Nokogiri::XML::Builder.new do |xml|
      xml.AuthSignature do
        xml.send('ds:SignedInfo') do
          xml.send('ds:CanonicalizationMethod', '', Algorithm: 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315')
          xml.send('ds:SignatureMethod', '', Algorithm: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256')
          xml.send('ds:Reference', '', URI: "#xpointer(//*[@authenticate='true'])") do
            xml.send('ds:Transforms') do
              xml.send('ds:Transform', '', Algorithm: 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315')
            end
            xml.send('ds:DigestMethod', '', Algorithm: 'http://www.w3.org/2001/04/xmlenc#sha256')
            xml.send('ds:DigestValue', '')
          end
        end
        xml.send('ds:SignatureValue', '')
      end
    end.doc.root
  end

  def to_transfer_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.send(root, 'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => client.urn_schema,
                     'Version' => client.version, 'Revision' => '1') do
        xml.header(authenticate: true) do
          xml.static do
            xml.HostID host_id
            xml.TransactionID transaction_id
          end
          xml.mutable do
            xml.TransactionPhase 'Transfer'
            xml.SegmentNumber(1, lastSegment: true)
          end
        end
        xml.parent.add_child(auth_signature)
        xml.body do
          xml.DataTransfer do
            xml.OrderData encrypted_order_data
          end
        end
      end
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end

  def to_receipt_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.send(root, 'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => client.urn_schema,
                     'Version' => client.version, 'Revision' => '1') do
        xml.header(authenticate: true) do
          xml.static do
            xml.HostID host_id
            xml.TransactionID(transaction_id)
          end
          xml.mutable do
            xml.TransactionPhase 'Receipt'
          end
        end
        xml.parent.add_child(auth_signature)
        xml.body do
          xml.TransferReceipt(authenticate: true) do
            xml.ReceiptCode 0
          end
        end
      end
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end

  def to_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.send(root, 'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#', 'xmlns' => client.urn_schema,
                     'Version' => client.version, 'Revision' => '1') do
        xml.parent.add_child(header)
        xml.parent.add_child(auth_signature)
        xml.parent.add_child(body)
      end
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end
end

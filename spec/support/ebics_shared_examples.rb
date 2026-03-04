RSpec.shared_examples '#to_xml' do |versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25, Epics::Keyring::VERSION_30]|
  describe '#to_xml' do
    versions.each do |version|
      context version do
        let(:version) { version }
        specify { expect(subject.to_xml).to be_a_valid_ebics_doc(version) }
      end
    end
  end
end

RSpec.shared_examples '#to_xml pending' do |versions:, reason: 'not yet implemented'|
  describe '#to_xml' do
    versions.each do |version|
      context version do
        let(:version) { version }
        specify(reason) { skip }
      end
    end
  end
end

RSpec.shared_examples '#to_transfer_xml' do |versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25, Epics::Keyring::VERSION_30]|
  describe '#to_transfer_xml' do
    versions.each do |version|
      context version do
        let(:version) { version }
        before { subject.transaction_id = SecureRandom.hex(16) }
        specify { expect(subject.to_transfer_xml).to be_a_valid_ebics_doc(version) }
      end
    end
  end
end

RSpec.shared_examples '#to_transfer_xml pending' do |versions:, reason: 'not yet implemented'|
  describe '#to_transfer_xml' do
    versions.each do |version|
      context version do
        let(:version) { version }
        specify(reason) { skip }
      end
    end
  end
end

RSpec.shared_examples '#to_receipt_xml' do |versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25, Epics::Keyring::VERSION_30]|
  describe '#to_receipt_xml' do
    versions.each do |version|
      context version do
        let(:version) { version }
        before { subject.transaction_id = SecureRandom.hex(16) }
        specify { expect(subject.to_receipt_xml).to be_a_valid_ebics_doc(version) }
      end
    end
  end
end

RSpec.shared_examples '#to_receipt_xml pending' do |versions:, reason: 'not yet implemented'|
  describe '#to_receipt_xml' do
    versions.each do |version|
      context version do
        let(:version) { version }
        specify(reason) { skip }
      end
    end
  end
end

# Structural shared examples for EBICS V2 requests (H003 and H004)
# These parse the XML with Nokogiri/XPath and validate each key element.
# Consumers must define:
#   let(:xml) { Nokogiri::XML(subject.to_xml) }
#   let(:ns)  { { 'e' => 'urn:org:ebics:H004' } }  # or 'http://www.ebics.org/H003'
#
# ebics_version defaults to 'H004'. Pass ebics_version: 'H003' for H003 tests.

# Helper to derive the expected namespace href from a version string.
module EbicsSharedExampleHelpers
  def self.expected_namespace(ebics_version)
    ebics_version == 'H003' ? "http://www.ebics.org/H003" : "urn:org:ebics:#{ebics_version}"
  end
end

RSpec.shared_examples 'a valid ebicsRequest header' do |order_type:, order_attribute:, ebics_version: 'H004'|
  expected_ns_href = EbicsSharedExampleHelpers.expected_namespace(ebics_version)

  it "has ebicsRequest root with #{ebics_version} namespace and Version" do
    root = xml.root
    expect(root.name).to eq('ebicsRequest')
    expect(root.namespace.href).to eq(expected_ns_href)
    expect(root['Version']).to eq(ebics_version)
    expect(root['Revision']).to eq('1')
  end

  it 'has header with authenticate=true' do
    header = xml.at_xpath('//e:header', ns)
    expect(header).not_to be_nil
    expect(header['authenticate']).to eq('true')
  end

  it 'has HostID in static header' do
    expect(xml.at_xpath('//e:header/e:static/e:HostID', ns).text).to eq('SIZBN001')
  end

  it 'has a valid 32-char hex Nonce' do
    nonce = xml.at_xpath('//e:header/e:static/e:Nonce', ns).text
    expect(nonce).to match(/\A[0-9a-f]{32}\z/)
  end

  it 'has a Timestamp' do
    timestamp = xml.at_xpath('//e:header/e:static/e:Timestamp', ns).text
    expect(timestamp).not_to be_empty
  end

  it 'has PartnerID and UserID' do
    expect(xml.at_xpath('//e:header/e:static/e:PartnerID', ns)).not_to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:UserID', ns)).not_to be_nil
  end

  it 'has Product element' do
    product = xml.at_xpath('//e:header/e:static/e:Product', ns)
    expect(product).not_to be_nil
  end

  it "has OrderType #{order_type}" do
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails/e:OrderType', ns).text).to eq(order_type)
  end

  it "has OrderAttribute #{order_attribute}" do
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails/e:OrderAttribute', ns).text).to eq(order_attribute)
  end

  it 'has BankPubKeyDigests with Authentication and Encryption versions' do
    digests = xml.at_xpath('//e:header/e:static/e:BankPubKeyDigests', ns)
    expect(digests).not_to be_nil

    auth = digests.at_xpath('e:Authentication', ns)
    expect(auth).not_to be_nil
    expect(auth['Version']).not_to be_empty

    enc = digests.at_xpath('e:Encryption', ns)
    expect(enc).not_to be_nil
    expect(enc['Version']).not_to be_empty
  end

  it 'has SecurityMedium 0000' do
    expect(xml.at_xpath('//e:header/e:static/e:SecurityMedium', ns).text).to eq('0000')
  end

  it 'has TransactionPhase Initialisation' do
    expect(xml.at_xpath('//e:header/e:mutable/e:TransactionPhase', ns).text).to eq('Initialisation')
  end

  it 'has AuthSignature element' do
    expect(xml.at_xpath('//e:AuthSignature', ns)).not_to be_nil
  end
end

RSpec.shared_examples 'a valid ebicsRequest download' do |order_type:, order_attribute: 'DZHNN', ebics_version: 'H004'|
  include_examples 'a valid ebicsRequest header',
    order_type: order_type, order_attribute: order_attribute, ebics_version: ebics_version

  it 'has an empty body (no DataTransfer)' do
    body = xml.at_xpath('//e:body', ns)
    expect(body).not_to be_nil
    expect(body.at_xpath('e:DataTransfer', ns)).to be_nil
  end
end

RSpec.shared_examples 'a valid ebicsRequest upload' do |order_type:, order_attribute: 'OZHNN', ebics_version: 'H004'|
  include_examples 'a valid ebicsRequest header',
    order_type: order_type, order_attribute: order_attribute, ebics_version: ebics_version

  it 'has StandardOrderParams' do
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails/e:StandardOrderParams', ns)).not_to be_nil
  end

  it 'has NumSegments' do
    expect(xml.at_xpath('//e:header/e:static/e:NumSegments', ns)).not_to be_nil
  end

  it 'has DataEncryptionInfo with authenticate=true' do
    dei = xml.at_xpath('//e:body/e:DataTransfer/e:DataEncryptionInfo', ns)
    expect(dei).not_to be_nil
    expect(dei['authenticate']).to eq('true')
  end

  it 'has EncryptionPubKeyDigest with Version' do
    epkd = xml.at_xpath('//e:body/e:DataTransfer/e:DataEncryptionInfo/e:EncryptionPubKeyDigest', ns)
    expect(epkd).not_to be_nil
    expect(epkd['Version']).not_to be_empty
  end

  it 'has TransactionKey' do
    expect(xml.at_xpath('//e:body/e:DataTransfer/e:DataEncryptionInfo/e:TransactionKey', ns)).not_to be_nil
  end

  it 'has SignatureData with authenticate=true' do
    sig_data = xml.at_xpath('//e:body/e:DataTransfer/e:SignatureData', ns)
    expect(sig_data).not_to be_nil
    expect(sig_data['authenticate']).to eq('true')
  end
end

RSpec.shared_examples 'a valid ebicsRequest download with date range' do |order_type:, from:, to:, ebics_version: 'H004'|
  include_examples 'a valid ebicsRequest download',
    order_type: order_type, ebics_version: ebics_version

  it 'has DateRange with correct Start and End dates' do
    date_range = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:StandardOrderParams/e:DateRange', ns)
    expect(date_range).not_to be_nil
    expect(date_range.at_xpath('e:Start', ns).text).to eq(from)
    expect(date_range.at_xpath('e:End', ns).text).to eq(to)
  end
end

RSpec.shared_examples 'a valid ebicsRequest receipt' do |ebics_version: 'H004'|
  expected_ns_href = EbicsSharedExampleHelpers.expected_namespace(ebics_version)

  it "has ebicsRequest root with #{ebics_version} namespace and Version" do
    root = xml.root
    expect(root.name).to eq('ebicsRequest')
    expect(root.namespace.href).to eq(expected_ns_href)
    expect(root['Version']).to eq(ebics_version)
    expect(root['Revision']).to eq('1')
  end

  it 'has header with authenticate=true' do
    header = xml.at_xpath('//e:header', ns)
    expect(header).not_to be_nil
    expect(header['authenticate']).to eq('true')
  end

  it 'has only HostID and TransactionID in static header' do
    expect(xml.at_xpath('//e:header/e:static/e:HostID', ns).text).to eq('SIZBN001')
    expect(xml.at_xpath('//e:header/e:static/e:TransactionID', ns)).not_to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:Nonce', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:PartnerID', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:UserID', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:BankPubKeyDigests', ns)).to be_nil
  end

  it 'has TransactionPhase Receipt' do
    expect(xml.at_xpath('//e:header/e:mutable/e:TransactionPhase', ns).text).to eq('Receipt')
  end

  it 'has AuthSignature element' do
    expect(xml.at_xpath('//e:AuthSignature', ns)).not_to be_nil
  end

  it 'has TransferReceipt with authenticate=true and ReceiptCode 0' do
    receipt = xml.at_xpath('//e:body/e:TransferReceipt', ns)
    expect(receipt).not_to be_nil
    expect(receipt['authenticate']).to eq('true')
    expect(receipt.at_xpath('e:ReceiptCode', ns).text).to eq('0')
  end
end

RSpec.shared_examples 'a valid ebicsRequest transfer' do |ebics_version: 'H004'|
  expected_ns_href = EbicsSharedExampleHelpers.expected_namespace(ebics_version)

  it "has ebicsRequest root with #{ebics_version} namespace and Version" do
    root = xml.root
    expect(root.name).to eq('ebicsRequest')
    expect(root.namespace.href).to eq(expected_ns_href)
    expect(root['Version']).to eq(ebics_version)
    expect(root['Revision']).to eq('1')
  end

  it 'has header with authenticate=true' do
    header = xml.at_xpath('//e:header', ns)
    expect(header).not_to be_nil
    expect(header['authenticate']).to eq('true')
  end

  it 'has only HostID and TransactionID in static header' do
    expect(xml.at_xpath('//e:header/e:static/e:HostID', ns).text).to eq('SIZBN001')
    expect(xml.at_xpath('//e:header/e:static/e:TransactionID', ns)).not_to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:Nonce', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:PartnerID', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:UserID', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:BankPubKeyDigests', ns)).to be_nil
  end

  it 'has TransactionPhase Transfer with SegmentNumber' do
    expect(xml.at_xpath('//e:header/e:mutable/e:TransactionPhase', ns).text).to eq('Transfer')
    seg = xml.at_xpath('//e:header/e:mutable/e:SegmentNumber', ns)
    expect(seg).not_to be_nil
    expect(seg['lastSegment']).to eq('true')
    expect(seg.text).to eq('1')
  end

  it 'has AuthSignature element' do
    expect(xml.at_xpath('//e:AuthSignature', ns)).not_to be_nil
  end

  it 'has OrderData in body but no DataEncryptionInfo or SignatureData' do
    expect(xml.at_xpath('//e:body/e:DataTransfer/e:OrderData', ns)).not_to be_nil
    expect(xml.at_xpath('//e:body/e:DataTransfer/e:DataEncryptionInfo', ns)).to be_nil
    expect(xml.at_xpath('//e:body/e:DataTransfer/e:SignatureData', ns)).to be_nil
  end
end

RSpec.shared_examples 'a valid ebicsRequest download with FDLOrderParams' do |order_type: 'FDL', file_format:, ebics_version: 'H004'|
  include_examples 'a valid ebicsRequest download',
    order_type: order_type, ebics_version: ebics_version

  it "has FDLOrderParams with FileFormat #{file_format}" do
    fdl_params = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:FDLOrderParams', ns)
    expect(fdl_params).not_to be_nil
    expect(fdl_params.at_xpath('e:FileFormat', ns).text).to eq(file_format)
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails/e:StandardOrderParams', ns)).to be_nil
  end
end

RSpec.shared_examples 'a valid ebicsRequest download with FDLOrderParams and date range' do |order_type: 'FDL', file_format:, from:, to:, ebics_version: 'H004'|
  include_examples 'a valid ebicsRequest download with FDLOrderParams',
    order_type: order_type, file_format: file_format, ebics_version: ebics_version

  it 'has DateRange within FDLOrderParams' do
    date_range = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:FDLOrderParams/e:DateRange', ns)
    expect(date_range).not_to be_nil
    expect(date_range.at_xpath('e:Start', ns).text).to eq(from)
    expect(date_range.at_xpath('e:End', ns).text).to eq(to)
  end
end

# Structural shared examples for EBICS V3/H005 requests
# H005 uses AdminOrderType instead of OrderType+OrderAttribute,
# and BTDOrderParams/BTUOrderParams instead of StandardOrderParams.

RSpec.shared_examples 'a valid ebicsRequest H005 header' do |admin_order_type:|
  expected_ns_href = 'urn:org:ebics:H005'

  it 'has ebicsRequest root with H005 namespace and Version' do
    root = xml.root
    expect(root.name).to eq('ebicsRequest')
    expect(root.namespace.href).to eq(expected_ns_href)
    expect(root['Version']).to eq('H005')
    expect(root['Revision']).to eq('1')
  end

  it 'has header with authenticate=true' do
    header = xml.at_xpath('//e:header', ns)
    expect(header).not_to be_nil
    expect(header['authenticate']).to eq('true')
  end

  it 'has HostID in static header' do
    expect(xml.at_xpath('//e:header/e:static/e:HostID', ns).text).to eq('SIZBN001')
  end

  it 'has a valid 32-char hex Nonce' do
    nonce = xml.at_xpath('//e:header/e:static/e:Nonce', ns).text
    expect(nonce).to match(/\A[0-9a-f]{32}\z/)
  end

  it 'has a Timestamp' do
    timestamp = xml.at_xpath('//e:header/e:static/e:Timestamp', ns).text
    expect(timestamp).not_to be_empty
  end

  it 'has PartnerID and UserID' do
    expect(xml.at_xpath('//e:header/e:static/e:PartnerID', ns)).not_to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:UserID', ns)).not_to be_nil
  end

  it 'has Product element' do
    product = xml.at_xpath('//e:header/e:static/e:Product', ns)
    expect(product).not_to be_nil
  end

  it "has AdminOrderType #{admin_order_type}" do
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails/e:AdminOrderType', ns).text).to eq(admin_order_type)
  end

  it 'does not have OrderType or OrderAttribute' do
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails/e:OrderType', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails/e:OrderAttribute', ns)).to be_nil
  end

  it 'has BankPubKeyDigests with Authentication and Encryption versions' do
    digests = xml.at_xpath('//e:header/e:static/e:BankPubKeyDigests', ns)
    expect(digests).not_to be_nil

    auth = digests.at_xpath('e:Authentication', ns)
    expect(auth).not_to be_nil
    expect(auth['Version']).not_to be_empty

    enc = digests.at_xpath('e:Encryption', ns)
    expect(enc).not_to be_nil
    expect(enc['Version']).not_to be_empty
  end

  it 'has SecurityMedium 0000' do
    expect(xml.at_xpath('//e:header/e:static/e:SecurityMedium', ns).text).to eq('0000')
  end

  it 'has TransactionPhase Initialisation' do
    expect(xml.at_xpath('//e:header/e:mutable/e:TransactionPhase', ns).text).to eq('Initialisation')
  end

  it 'has AuthSignature element' do
    expect(xml.at_xpath('//e:AuthSignature', ns)).not_to be_nil
  end
end

RSpec.shared_examples 'a valid ebicsRequest H005 download' do |service_name:, msg_name:, scope: nil, service_option: nil|
  include_examples 'a valid ebicsRequest H005 header', admin_order_type: 'BTD'

  it 'has BTDOrderParams with Service element' do
    btd = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:BTDOrderParams', ns)
    expect(btd).not_to be_nil
    service = btd.at_xpath('e:Service', ns)
    expect(service).not_to be_nil
    expect(service.at_xpath('e:ServiceName', ns).text).to eq(service_name)
    expect(service.at_xpath('e:MsgName', ns).text).to eq(msg_name)
  end

  if scope
    it "has Scope #{scope}" do
      service = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:BTDOrderParams/e:Service', ns)
      expect(service.at_xpath('e:Scope', ns).text).to eq(scope)
    end
  end

  if service_option
    it "has ServiceOption #{service_option}" do
      service = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:BTDOrderParams/e:Service', ns)
      expect(service.at_xpath('e:ServiceOption', ns).text).to eq(service_option)
    end
  end

  it 'has an empty body (no DataTransfer)' do
    body = xml.at_xpath('//e:body', ns)
    expect(body).not_to be_nil
    expect(body.at_xpath('e:DataTransfer', ns)).to be_nil
  end

  it 'does not have StandardOrderParams' do
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails/e:StandardOrderParams', ns)).to be_nil
  end
end

RSpec.shared_examples 'a valid ebicsRequest H005 download with date range' do |service_name:, msg_name:, from:, to:, scope: nil, service_option: nil|
  include_examples 'a valid ebicsRequest H005 download',
    service_name: service_name, msg_name: msg_name, scope: scope, service_option: service_option

  it 'has DateRange within BTDOrderParams' do
    date_range = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:BTDOrderParams/e:DateRange', ns)
    expect(date_range).not_to be_nil
    expect(date_range.at_xpath('e:Start', ns).text).to eq(from)
    expect(date_range.at_xpath('e:End', ns).text).to eq(to)
  end
end

RSpec.shared_examples 'a valid ebicsRequest H005 upload' do |service_name:, msg_name:, scope: nil, service_option: nil|
  include_examples 'a valid ebicsRequest H005 header', admin_order_type: 'BTU'

  it 'has BTUOrderParams with Service element' do
    btu = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:BTUOrderParams', ns)
    expect(btu).not_to be_nil
    expect(btu['fileName']).not_to be_nil
    service = btu.at_xpath('e:Service', ns)
    expect(service).not_to be_nil
    expect(service.at_xpath('e:ServiceName', ns).text).to eq(service_name)
    expect(service.at_xpath('e:MsgName', ns).text).to eq(msg_name)
  end

  if scope
    it "has Scope #{scope}" do
      service = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:BTUOrderParams/e:Service', ns)
      expect(service.at_xpath('e:Scope', ns).text).to eq(scope)
    end
  end

  if service_option
    it "has ServiceOption #{service_option}" do
      service = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:BTUOrderParams/e:Service', ns)
      expect(service.at_xpath('e:ServiceOption', ns).text).to eq(service_option)
    end
  end

  it 'has NumSegments' do
    expect(xml.at_xpath('//e:header/e:static/e:NumSegments', ns)).not_to be_nil
  end

  it 'has DataEncryptionInfo with authenticate=true' do
    dei = xml.at_xpath('//e:body/e:DataTransfer/e:DataEncryptionInfo', ns)
    expect(dei).not_to be_nil
    expect(dei['authenticate']).to eq('true')
  end

  it 'has SignatureData with authenticate=true' do
    sig_data = xml.at_xpath('//e:body/e:DataTransfer/e:SignatureData', ns)
    expect(sig_data).not_to be_nil
    expect(sig_data['authenticate']).to eq('true')
  end

  it 'has DataDigest element' do
    data_digest = xml.at_xpath('//e:body/e:DataTransfer/e:DataDigest', ns)
    expect(data_digest).not_to be_nil
    expect(data_digest['SignatureVersion']).not_to be_empty
  end

  it 'has AdditionalOrderInfo element' do
    expect(xml.at_xpath('//e:body/e:DataTransfer/e:AdditionalOrderInfo', ns)).not_to be_nil
  end

  it 'does not have StandardOrderParams' do
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails/e:StandardOrderParams', ns)).to be_nil
  end
end

RSpec.shared_examples 'a valid ebicsRequest H005 receipt' do
  expected_ns_href = 'urn:org:ebics:H005'

  it 'has ebicsRequest root with H005 namespace and Version' do
    root = xml.root
    expect(root.name).to eq('ebicsRequest')
    expect(root.namespace.href).to eq(expected_ns_href)
    expect(root['Version']).to eq('H005')
    expect(root['Revision']).to eq('1')
  end

  it 'has header with authenticate=true' do
    header = xml.at_xpath('//e:header', ns)
    expect(header).not_to be_nil
    expect(header['authenticate']).to eq('true')
  end

  it 'has only HostID and TransactionID in static header' do
    expect(xml.at_xpath('//e:header/e:static/e:HostID', ns).text).to eq('SIZBN001')
    expect(xml.at_xpath('//e:header/e:static/e:TransactionID', ns)).not_to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:Nonce', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:PartnerID', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:UserID', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:BankPubKeyDigests', ns)).to be_nil
  end

  it 'has TransactionPhase Receipt' do
    expect(xml.at_xpath('//e:header/e:mutable/e:TransactionPhase', ns).text).to eq('Receipt')
  end

  it 'has AuthSignature element' do
    expect(xml.at_xpath('//e:AuthSignature', ns)).not_to be_nil
  end

  it 'has TransferReceipt with authenticate=true and ReceiptCode 0' do
    receipt = xml.at_xpath('//e:body/e:TransferReceipt', ns)
    expect(receipt).not_to be_nil
    expect(receipt['authenticate']).to eq('true')
    expect(receipt.at_xpath('e:ReceiptCode', ns).text).to eq('0')
  end
end

RSpec.shared_examples 'a valid ebicsRequest H005 transfer' do
  expected_ns_href = 'urn:org:ebics:H005'

  it 'has ebicsRequest root with H005 namespace and Version' do
    root = xml.root
    expect(root.name).to eq('ebicsRequest')
    expect(root.namespace.href).to eq(expected_ns_href)
    expect(root['Version']).to eq('H005')
    expect(root['Revision']).to eq('1')
  end

  it 'has header with authenticate=true' do
    header = xml.at_xpath('//e:header', ns)
    expect(header).not_to be_nil
    expect(header['authenticate']).to eq('true')
  end

  it 'has only HostID and TransactionID in static header' do
    expect(xml.at_xpath('//e:header/e:static/e:HostID', ns).text).to eq('SIZBN001')
    expect(xml.at_xpath('//e:header/e:static/e:TransactionID', ns)).not_to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:Nonce', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:PartnerID', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:UserID', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails', ns)).to be_nil
    expect(xml.at_xpath('//e:header/e:static/e:BankPubKeyDigests', ns)).to be_nil
  end

  it 'has TransactionPhase Transfer with SegmentNumber' do
    expect(xml.at_xpath('//e:header/e:mutable/e:TransactionPhase', ns).text).to eq('Transfer')
    seg = xml.at_xpath('//e:header/e:mutable/e:SegmentNumber', ns)
    expect(seg).not_to be_nil
    expect(seg['lastSegment']).to eq('true')
    expect(seg.text).to eq('1')
  end

  it 'has AuthSignature element' do
    expect(xml.at_xpath('//e:AuthSignature', ns)).not_to be_nil
  end

  it 'has OrderData in body but no DataEncryptionInfo or SignatureData' do
    expect(xml.at_xpath('//e:body/e:DataTransfer/e:OrderData', ns)).not_to be_nil
    expect(xml.at_xpath('//e:body/e:DataTransfer/e:DataEncryptionInfo', ns)).to be_nil
    expect(xml.at_xpath('//e:body/e:DataTransfer/e:SignatureData', ns)).to be_nil
  end
end

RSpec.shared_examples 'a valid ebicsRequest upload with FULOrderParams' do |order_type: 'FUL', order_attribute: 'DZHNN', file_format:, ebics_version: 'H004'|
  include_examples 'a valid ebicsRequest header',
    order_type: order_type, order_attribute: order_attribute, ebics_version: ebics_version

  it "has FULOrderParams with FileFormat #{file_format}" do
    ful_params = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:FULOrderParams', ns)
    expect(ful_params).not_to be_nil
    expect(ful_params.at_xpath('e:FileFormat', ns).text).to eq(file_format)
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails/e:StandardOrderParams', ns)).to be_nil
  end

  it 'has NumSegments' do
    expect(xml.at_xpath('//e:header/e:static/e:NumSegments', ns)).not_to be_nil
  end

  it 'has DataEncryptionInfo with authenticate=true' do
    dei = xml.at_xpath('//e:body/e:DataTransfer/e:DataEncryptionInfo', ns)
    expect(dei).not_to be_nil
    expect(dei['authenticate']).to eq('true')
  end

  it 'has EncryptionPubKeyDigest with Version' do
    epkd = xml.at_xpath('//e:body/e:DataTransfer/e:DataEncryptionInfo/e:EncryptionPubKeyDigest', ns)
    expect(epkd).not_to be_nil
    expect(epkd['Version']).not_to be_empty
  end

  it 'has TransactionKey' do
    expect(xml.at_xpath('//e:body/e:DataTransfer/e:DataEncryptionInfo/e:TransactionKey', ns)).not_to be_nil
  end

  it 'has SignatureData with authenticate=true' do
    sig_data = xml.at_xpath('//e:body/e:DataTransfer/e:SignatureData', ns)
    expect(sig_data).not_to be_nil
    expect(sig_data['authenticate']).to eq('true')
  end
end

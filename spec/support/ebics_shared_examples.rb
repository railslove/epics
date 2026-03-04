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

# Structural shared examples for H004 requests
# These parse the XML with Nokogiri/XPath and validate each key element.
# Consumers must define: let(:xml) { Nokogiri::XML(subject.to_xml) }
#                         let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

RSpec.shared_examples 'a valid H004 request header' do |order_type:, order_attribute:|
  it 'has ebicsRequest root with H004 namespace and Version' do
    root = xml.root
    expect(root.name).to eq('ebicsRequest')
    expect(root.namespace.href).to eq('urn:org:ebics:H004')
    expect(root['Version']).to eq('H004')
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

RSpec.shared_examples 'a valid H004 download request' do |order_type:, order_attribute: 'DZHNN'|
  include_examples 'a valid H004 request header',
    order_type: order_type, order_attribute: order_attribute

  it 'has an empty body (no DataTransfer)' do
    body = xml.at_xpath('//e:body', ns)
    expect(body).not_to be_nil
    expect(body.at_xpath('e:DataTransfer', ns)).to be_nil
  end
end

RSpec.shared_examples 'a valid H004 upload request' do |order_type:, order_attribute: 'OZHNN'|
  include_examples 'a valid H004 request header',
    order_type: order_type, order_attribute: order_attribute

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

RSpec.shared_examples 'a valid H004 download request with date range' do |order_type:, from:, to:|
  include_examples 'a valid H004 download request', order_type: order_type

  it 'has DateRange with correct Start and End dates' do
    date_range = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:StandardOrderParams/e:DateRange', ns)
    expect(date_range).not_to be_nil
    expect(date_range.at_xpath('e:Start', ns).text).to eq(from)
    expect(date_range.at_xpath('e:End', ns).text).to eq(to)
  end
end

RSpec.shared_examples 'a valid H004 receipt request' do
  it 'has ebicsRequest root with H004 namespace and Version' do
    root = xml.root
    expect(root.name).to eq('ebicsRequest')
    expect(root.namespace.href).to eq('urn:org:ebics:H004')
    expect(root['Version']).to eq('H004')
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

RSpec.shared_examples 'a valid H004 transfer request' do
  it 'has ebicsRequest root with H004 namespace and Version' do
    root = xml.root
    expect(root.name).to eq('ebicsRequest')
    expect(root.namespace.href).to eq('urn:org:ebics:H004')
    expect(root['Version']).to eq('H004')
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

RSpec.shared_examples 'a valid H004 download request with FDLOrderParams' do |order_type: 'FDL', file_format:|
  include_examples 'a valid H004 download request', order_type: order_type

  it "has FDLOrderParams with FileFormat #{file_format}" do
    fdl_params = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:FDLOrderParams', ns)
    expect(fdl_params).not_to be_nil
    expect(fdl_params.at_xpath('e:FileFormat', ns).text).to eq(file_format)
    expect(xml.at_xpath('//e:header/e:static/e:OrderDetails/e:StandardOrderParams', ns)).to be_nil
  end
end

RSpec.shared_examples 'a valid H004 download request with FDLOrderParams and date range' do |order_type: 'FDL', file_format:, from:, to:|
  include_examples 'a valid H004 download request with FDLOrderParams',
    order_type: order_type, file_format: file_format

  it 'has DateRange within FDLOrderParams' do
    date_range = xml.at_xpath('//e:header/e:static/e:OrderDetails/e:FDLOrderParams/e:DateRange', ns)
    expect(date_range).not_to be_nil
    expect(date_range.at_xpath('e:Start', ns).text).to eq(from)
    expect(date_range.at_xpath('e:End', ns).text).to eq(to)
  end
end

RSpec.shared_examples 'a valid H004 upload request with FULOrderParams' do |order_type: 'FUL', order_attribute: 'DZHNN', file_format:|
  include_examples 'a valid H004 request header',
    order_type: order_type, order_attribute: order_attribute

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

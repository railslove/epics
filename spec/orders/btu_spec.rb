RSpec.describe Epics::BTU do
  let(:client) do
    Epics::Client.new(
      File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')),
      'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS',
      version: :h005
    )
  end

  let(:document) { File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'cd1.xml')) }
  let(:service) do
    Epics::BTF.new(service_name: 'SCT', scope: 'DE', msg_name: 'pain.001', msg_version: '03')
  end

  subject(:order) { described_class.new(client, document, service: service) }

  describe 'H005 envelope' do
    it { expect(order.to_xml).to include('xmlns="urn:org:ebics:H005"') }
    it { expect(order.to_xml).to include('Version="H005"') }
  end

  describe 'OrderDetails / BTF' do
    let(:header) { order.header.to_s }

    it { expect(header).to include('<AdminOrderType>BTU</AdminOrderType>') }
    it { expect(header).to include('<BTUOrderParams>') }
    it { expect(header).to include('<ServiceName>SCT</ServiceName>') }
    it { expect(header).to include('<MsgName version="03">pain.001</MsgName>') }
    it { expect(header).to match(%r{<SignatureFlag\s*/>}) }
    it { expect(header).not_to include('OrderAttribute') }
  end

  describe 'signature flag' do
    it 'omits SignatureFlag when the order carries no ES' do
      order = described_class.new(client, document, service: service, signature_flag: false)
      expect(order.header.to_s).not_to include('SignatureFlag')
    end

    it 'adds requestEDS for distributed signature' do
      order = described_class.new(client, document, service: service, request_eds: true)
      expect(order.header.to_s).to include('requestEDS="true"')
    end
  end

  describe 'H005 upload body' do
    it 'includes a DataDigest with the A006 signature version' do
      expect(order.to_xml).to match(%r{<DataDigest SignatureVersion="A006">.+</DataDigest>})
    end
  end

  describe '#to_xml' do
    specify { expect(order.to_xml).to be_a_valid_ebics_doc(:h005) } if ebics_xsd_available?(:h005)
  end

  describe '#to_transfer_xml' do
    before { order.transaction_id = SecureRandom.hex(16) }
    it { expect(order.to_transfer_xml).to include('xmlns="urn:org:ebics:H005"') }
  end
end

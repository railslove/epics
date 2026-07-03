RSpec.describe Epics::BTD do
  let(:client) do
    Epics::Client.new(
      File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')),
      'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS',
      version: :h005
    )
  end

  let(:service) do
    Epics::BTF.new(service_name: 'EOP', scope: 'DE', container: 'ZIP', msg_name: 'camt.053', msg_version: '08')
  end

  subject(:order) { described_class.new(client, service: service, from: '2026-01-01', to: '2026-01-31') }

  describe 'H005 envelope' do
    it { expect(order.to_xml).to include('xmlns="urn:org:ebics:H005"') }
    it { expect(order.to_xml).to include('Version="H005"') }
  end

  describe 'OrderDetails / BTF' do
    let(:header) { order.header.to_s }

    it { expect(header).to include('<AdminOrderType>BTD</AdminOrderType>') }
    it { expect(header).to include('<BTDOrderParams>') }
    it { expect(header).to include('<ServiceName>EOP</ServiceName>') }
    it { expect(header).to include('<Scope>DE</Scope>') }
    it { expect(header).to include('<Container containerType="ZIP"/>') }
    it { expect(header).to include('<MsgName version="08">camt.053</MsgName>') }
    it { expect(header).to match(%r{<DateRange>\s*<Start>2026-01-01</Start>\s*<End>2026-01-31</End>\s*</DateRange>}) }
    it { expect(header).not_to include('OrderAttribute') }
  end

  describe '#to_xml' do
    specify { expect(order.to_xml).to be_a_valid_ebics_doc(:h005) } if ebics_xsd_available?(:h005)
  end

  describe '#to_receipt_xml' do
    before { order.transaction_id = SecureRandom.hex(16) }
    it { expect(order.to_receipt_xml).to include('xmlns="urn:org:ebics:H005"') }
  end
end

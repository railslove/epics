RSpec.describe Epics::VPZ do
  let(:key_file) { File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')) }
  let(:client) do
    Epics::Client.new(key_file, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS',
                      version:)
  end
  let(:xml) { Nokogiri::XML(subject.to_xml) }

  describe 'H005' do
    let(:version) { Epics::Keyring::VERSION_30 }
    let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

    context 'without a date range' do
      subject { described_class.new(client) }

      include_examples '#to_xml', versions: [Epics::Keyring::VERSION_30]
      include_examples 'a valid ebicsRequest H005 download',
        service_name: 'REP', msg_name: 'pain.002', scope: 'DE', service_option: 'VOP'

      it 'asks for a ZIP container' do
        container = xml.at_xpath('//e:BTDOrderParams/e:Service/e:Container', ns)
        expect(container['containerType']).to eq('ZIP')
      end

      it 'sends no DateRange' do
        expect(xml.at_xpath('//e:OrderDetails/e:BTDOrderParams/e:DateRange', ns)).to be_nil
      end
    end

    context 'with a date range' do
      subject { described_class.new(client, from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 11)) }

      include_examples '#to_xml', versions: [Epics::Keyring::VERSION_30]
      include_examples 'a valid ebicsRequest H005 download with date range',
        service_name: 'REP', msg_name: 'pain.002', scope: 'DE', service_option: 'VOP',
        from: '2026-11-01', to: '2026-11-11'
    end
  end

  describe 'H004' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    context 'without a date range' do
      subject { described_class.new(client) }

      include_examples '#to_xml', versions: [Epics::Keyring::VERSION_25]
      include_examples 'a valid ebicsRequest download', order_type: 'VPZ'
    end

    context 'with a date range' do
      subject { described_class.new(client, from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 11)) }

      include_examples '#to_xml', versions: [Epics::Keyring::VERSION_25]
      include_examples 'a valid ebicsRequest download with date range',
        order_type: 'VPZ', from: '2026-11-01', to: '2026-11-11'
    end
  end
end

RSpec.describe Epics::HVD do
  let(:key_file) { File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')) }
  let(:client) do
    Epics::Client.new(key_file, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS',
                      version:)
  end
  let(:xml) { Nokogiri::XML(subject.to_xml) }

  subject { described_class.new(client, order_id: 'N02A', service: service) }

  describe 'H005' do
    let(:version) { Epics::Keyring::VERSION_30 }
    let(:service) { { service_name: 'SCT', service_option: 'VOI', msg_name: 'pain.001' } }
    let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

    include_examples '#to_xml', versions: [Epics::Keyring::VERSION_30]
    include_examples 'a valid ebicsRequest H005 header', admin_order_type: 'HVD'

    it 'identifies the order by partner, service and order ID' do
      params = xml.at_xpath('//e:OrderDetails/e:HVDOrderParams', ns)
      expect(params.at_xpath('e:PartnerID', ns).text).to eq('EBICS')
      expect(params.at_xpath('e:Service/e:ServiceName', ns).text).to eq('SCT')
      expect(params.at_xpath('e:Service/e:ServiceOption', ns).text).to eq('VOI')
      expect(params.at_xpath('e:Service/e:MsgName', ns).text).to eq('pain.001')
      expect(params.at_xpath('e:Service/e:Scope', ns)).to be_nil
      expect(params.at_xpath('e:Service/e:Container', ns)).to be_nil
      expect(params.at_xpath('e:OrderID', ns).text).to eq('N02A')
    end

    context 'with scope and container in the service' do
      let(:service) do
        { service_name: 'SCT', scope: 'DE', service_option: 'VOI', container_type: 'ZIP', msg_name: 'pain.001' }
      end

      include_examples '#to_xml', versions: [Epics::Keyring::VERSION_30]

      it 'renders the service elements in schema order' do
        service_node = xml.at_xpath('//e:OrderDetails/e:HVDOrderParams/e:Service', ns)
        expect(service_node.element_children.map(&:name)).to eq(%w[ServiceName Scope ServiceOption Container MsgName])
        expect(service_node.at_xpath('e:Scope', ns).text).to eq('DE')
        expect(service_node.at_xpath('e:Container', ns)['containerType']).to eq('ZIP')
      end
    end
  end

  describe 'H004' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:service) { 'CTV' }
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    include_examples '#to_xml', versions: [Epics::Keyring::VERSION_25]
    include_examples 'a valid ebicsRequest download', order_type: 'HVD'

    it 'identifies the order by partner, order type and order ID' do
      params = xml.at_xpath('//e:OrderDetails/e:HVDOrderParams', ns)
      expect(params.at_xpath('e:PartnerID', ns).text).to eq('EBICS')
      expect(params.at_xpath('e:OrderType', ns).text).to eq('CTV')
      expect(params.at_xpath('e:OrderID', ns).text).to eq('N02A')
    end
  end
end

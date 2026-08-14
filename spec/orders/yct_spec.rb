RSpec.describe Epics::YCT do
  let(:client) do
    Epics::Client.new(File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')),
                      'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS',
                      version: version)
  end
  let(:document) { File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'cd1.xml')) }

  subject { described_class.new(client, document) }

  include_examples '#to_xml', versions: [Epics::Keyring::VERSION_30]
  include_examples '#to_transfer_xml', versions: [Epics::Keyring::VERSION_30]

  describe 'H005 request structure' do
    let(:version) { Epics::Keyring::VERSION_30 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

    include_examples 'a valid ebicsRequest H005 upload',
                     service_name: 'MCT', msg_name: 'pain.001', scope: 'BIL'

    it 'names the file after the message type' do
      expect(xml.at_xpath('//e:BTUOrderParams', ns)['fileName']).to eq('yct.pain.001.xxx.xml')
    end

    it 'accepts overrides' do
      order = described_class.new(client, document, service_option: 'CH001YCT')
      service = Nokogiri::XML(order.to_xml).at_xpath('//e:Service', ns)

      expect(service.at_xpath('e:ServiceOption', ns).text).to eq('CH001YCT')
    end
  end

  [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25].each do |older|
    describe older do
      let(:version) { older }

      it 'raises' do
        expect { subject.to_xml }.to raise_error(Epics::VersionSupportError, 'Supported from version 3.0')
      end
    end
  end
end

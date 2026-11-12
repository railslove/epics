RSpec.describe Epics::HVU do
  let(:key_file) { File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')) }
  let(:client) do
    Epics::Client.new(key_file, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS',
                      version:)
  end
  let(:xml) { Nokogiri::XML(subject.to_xml) }

  subject { described_class.new(client) }

  describe 'H005' do
    let(:version) { Epics::Keyring::VERSION_30 }
    let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

    include_examples '#to_xml', versions: [Epics::Keyring::VERSION_30]
    include_examples 'a valid ebicsRequest H005 header', admin_order_type: 'HVU'

    it 'asks for every order waiting for the user' do
      params = xml.at_xpath('//e:OrderDetails/e:HVUOrderParams', ns)
      expect(params).not_to be_nil
      expect(params.element_children).to be_empty
    end
  end

  describe 'H004' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    include_examples '#to_xml', versions: [Epics::Keyring::VERSION_25]
    include_examples 'a valid ebicsRequest download', order_type: 'HVU'

    it 'asks for every order waiting for the user' do
      params = xml.at_xpath('//e:OrderDetails/e:HVUOrderParams', ns)
      expect(params).not_to be_nil
      expect(params.element_children).to be_empty
    end
  end
end

RSpec.describe Epics::Z54 do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }

  subject { described_class.new(client, from: Date.parse('2014-09-01'), to: Date.parse('2014-09-30')) }

  describe 'order attributes' do
    let(:version) { Epics::Keyring::VERSION_25 }

    it { expect(subject.to_xml).to include('<OrderAttribute>DZHNN</OrderAttribute>') }
    it { expect(subject.to_xml).to include('<OrderType>Z54</OrderType>') }
  end

  include_examples '#to_xml'

  describe 'H005 request structure' do
    let(:version) { Epics::Keyring::VERSION_30 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

    include_examples 'a valid ebicsRequest H005 download with date range',
      service_name: 'REP', msg_name: 'camt.054', from: '2014-09-01', to: '2014-09-30'

    it 'has no ServiceOption' do
      expect(xml.at_xpath('//e:BTDOrderParams/e:Service/e:ServiceOption', ns)).to be_nil
    end

    context 'with service_option XQRR (ZQR, QR reference payments only)' do
      subject { described_class.new(client, from: Date.parse('2014-09-01'), to: Date.parse('2014-09-30'), service_option: 'XQRR') }

      include_examples 'a valid ebicsRequest H005 download with date range',
        service_name: 'REP', msg_name: 'camt.054', service_option: 'XQRR', from: '2014-09-01', to: '2014-09-30'
    end
  end

  describe 'H004 request structure' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    include_examples 'a valid ebicsRequest download with date range',
      order_type: 'Z54', from: '2014-09-01', to: '2014-09-30'
  end

  describe 'H003 request structure' do
    let(:version) { Epics::Keyring::VERSION_24 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

    include_examples 'a valid ebicsRequest download with date range',
      order_type: 'Z54', from: '2014-09-01', to: '2014-09-30', ebics_version: 'H003'
  end
end

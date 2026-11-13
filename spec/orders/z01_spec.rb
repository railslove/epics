RSpec.describe Epics::Z01 do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }

  subject { described_class.new(client, from: Date.parse('2014-09-01'), to: Date.parse('2014-09-30')) }

  describe 'order attributes' do
    let(:version) { Epics::Keyring::VERSION_25 }

    it { expect(subject.to_xml).to include('<OrderAttribute>DZHNN</OrderAttribute>') }
    it { expect(subject.to_xml).to include('<OrderType>Z01</OrderType>') }
  end

  include_examples '#to_xml'

  describe 'H005 request structure' do
    let(:version) { Epics::Keyring::VERSION_30 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

    include_examples 'a valid ebicsRequest H005 download with date range',
      service_name: 'PSR', msg_name: 'pain.002', from: '2014-09-01', to: '2014-09-30'

    it 'has no ServiceOption' do
      expect(xml.at_xpath('//e:BTDOrderParams/e:Service/e:ServiceOption', ns)).to be_nil
    end

    it 'requests a ZIP container by default' do
      expect(xml.at_xpath('//e:BTDOrderParams/e:Service/e:Container/@containerType', ns).value).to eq('ZIP')
    end

    context 'with container_type: false (e.g. pain.002 v10 at the ZKB)' do
      subject do
        described_class.new(client, from: Date.parse('2014-09-01'), to: Date.parse('2014-09-30'),
                                    scope: 'CH', msg_name_version: '10', container_type: false)
      end

      include_examples 'a valid ebicsRequest H005 download with date range',
        service_name: 'PSR', msg_name: 'pain.002', scope: 'CH', from: '2014-09-01', to: '2014-09-30'

      it 'has no Container' do
        expect(xml.at_xpath('//e:BTDOrderParams/e:Service/e:Container', ns)).to be_nil
      end

      it 'has MsgName version 10' do
        expect(xml.at_xpath('//e:BTDOrderParams/e:Service/e:MsgName/@version', ns).value).to eq('10')
      end
    end

    context 'with container_type: nil' do
      subject { described_class.new(client, from: Date.parse('2014-09-01'), to: Date.parse('2014-09-30'), container_type: nil) }

      it 'falls back to the ZIP container' do
        expect(xml.at_xpath('//e:BTDOrderParams/e:Service/e:Container/@containerType', ns).value).to eq('ZIP')
      end
    end
  end

  describe 'H004 request structure' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    include_examples 'a valid ebicsRequest download with date range',
      order_type: 'Z01', from: '2014-09-01', to: '2014-09-30'
  end

  describe 'H003 request structure' do
    let(:version) { Epics::Keyring::VERSION_24 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

    include_examples 'a valid ebicsRequest download with date range',
      order_type: 'Z01', from: '2014-09-01', to: '2014-09-30', ebics_version: 'H003'
  end
end

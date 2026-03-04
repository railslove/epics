RSpec.describe Epics::CRZ do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  
  context 'with date range' do
    subject { described_class.new(client, from: Date.parse('2014-09-01'), to: Date.parse('2014-09-30')) }

    include_examples '#to_xml'

    describe '#to_xml' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it 'does includes a date range as standard order parameter' do
        expect(subject.to_xml).to include('<StandardOrderParams><DateRange><Start>2014-09-01</Start><End>2014-09-30</End></DateRange></StandardOrderParams>')
      end
    end

    describe 'H005 request structure' do
      let(:version) { Epics::Keyring::VERSION_30 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

      include_examples 'a valid ebicsRequest H005 download with date range',
        service_name: 'REP', msg_name: 'pain.002', scope: 'DE', service_option: 'SCT', from: '2014-09-01', to: '2014-09-30'
    end

    describe 'H004 request structure' do
      let(:version) { Epics::Keyring::VERSION_25 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

      include_examples 'a valid ebicsRequest download with date range',
        order_type: 'CRZ', from: '2014-09-01', to: '2014-09-30'
    end

    describe 'H003 request structure' do
      let(:version) { Epics::Keyring::VERSION_24 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

      include_examples 'a valid ebicsRequest download with date range',
        order_type: 'CRZ', from: '2014-09-01', to: '2014-09-30', ebics_version: 'H003'
    end
  end

  context 'without date range' do
    subject { described_class.new(client) }

    describe 'order attributes' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it { expect(subject.to_xml).to include('<OrderAttribute>DZHNN</OrderAttribute>') }
      it { expect(subject.to_xml).to include('<OrderType>CRZ</OrderType>') }
    end

    include_examples '#to_xml'

    describe '#to_xml' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it 'does not include a standard order parameter' do
        expect(subject.to_xml).to include('<StandardOrderParams/>')
      end
    end

    describe 'H005 request structure' do
      let(:version) { Epics::Keyring::VERSION_30 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

      include_examples 'a valid ebicsRequest H005 download',
        service_name: 'REP', msg_name: 'pain.002', scope: 'DE', service_option: 'SCT'
    end

    describe 'H004 request structure' do
      let(:version) { Epics::Keyring::VERSION_25 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

      include_examples 'a valid ebicsRequest download', order_type: 'CRZ'
    end

    describe 'H003 request structure' do
      let(:version) { Epics::Keyring::VERSION_24 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

      include_examples 'a valid ebicsRequest download', order_type: 'CRZ', ebics_version: 'H003'
    end
  end
end

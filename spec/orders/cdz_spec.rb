RSpec.describe Epics::CDZ do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }

  context 'with date range' do
    subject { described_class.new(client, from: Date.parse('2014-09-01'), to: Date.parse('2014-09-30')) }

    include_examples '#to_xml pending', versions: [Epics::Keyring::VERSION_24], reason: 'H003 download support not yet implemented'
    include_examples '#to_xml', versions: [Epics::Keyring::VERSION_25]
    include_examples '#to_xml pending', versions: [Epics::Keyring::VERSION_30], reason: 'H005 BTD mapping not yet implemented'

    describe '#to_xml' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it 'does includes a date range as standard order parameter' do
        expect(subject.to_xml).to include('<StandardOrderParams><DateRange><Start>2014-09-01</Start><End>2014-09-30</End></DateRange></StandardOrderParams>')
      end
    end

    describe 'H004 request structure' do
      let(:version) { Epics::Keyring::VERSION_25 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

      include_examples 'a valid H004 download request with date range',
        order_type: 'CDZ', from: '2014-09-01', to: '2014-09-30'
    end
  end

  context 'without date range' do
    subject { described_class.new(client) }

    describe 'order attributes' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it { expect(subject.to_xml).to include('<OrderAttribute>DZHNN</OrderAttribute>') }
      it { expect(subject.to_xml).to include('<OrderType>CDZ</OrderType>') }
    end

    include_examples '#to_xml pending', versions: [Epics::Keyring::VERSION_24], reason: 'H003 download support not yet implemented'
    include_examples '#to_xml', versions: [Epics::Keyring::VERSION_25]
    include_examples '#to_xml pending', versions: [Epics::Keyring::VERSION_30], reason: 'H005 BTD mapping not yet implemented'

    describe '#to_xml' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it 'does not include a standard order parameter' do
        expect(subject.to_xml).to include('<StandardOrderParams/>')
      end
    end

    describe 'H004 request structure' do
      let(:version) { Epics::Keyring::VERSION_25 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

      include_examples 'a valid H004 download request', order_type: 'CDZ'
    end
  end
end

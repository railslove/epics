RSpec.describe Epics::CRZ do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  
  context 'with date range' do
    subject { described_class.new(client, from: "2014-09-01", to: "2014-09-30") }

    include_examples '#to_xml'

    describe '#to_xml' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it 'does includes a date range as standard order parameter' do
        expect(subject.to_xml).to include('<StandardOrderParams><DateRange><Start>2014-09-01</Start><End>2014-09-30</End></DateRange></StandardOrderParams>')
      end
    end
  end

  context 'without date range' do
    subject { described_class.new(client) }

    include_examples '#to_xml'

    describe '#to_xml' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it 'does not include a standard order parameter' do
        expect(subject.to_xml).to include('<StandardOrderParams/>')
      end
    end
  end
end

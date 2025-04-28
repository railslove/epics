RSpec.describe Epics::FDL do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  let(:file_format) { 'camt.xxx.cfonb120.stm.Oby' }

  context 'with file_format' do
    subject(:order) { described_class.new(client, file_format: file_format) }

    include_examples '#to_xml'
    include_examples '#to_receipt_xml'

    describe '#to_xml' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it 'does includes a date range as standard order parameter' do
        expect(order.to_xml).to include('<FDLOrderParams><FileFormat>camt.xxx.cfonb120.stm.Oby</FileFormat></FDLOrderParams>')
      end
    end

    context 'with DateRange' do
      subject(:order) { described_class.new(client, file_format: file_format, from: Date.new(2024, 1, 1), to: Date.new(2024, 1, 2)) }

      include_examples '#to_xml'
      include_examples '#to_receipt_xml'

      describe '#to_xml' do
        let(:version) { Epics::Keyring::VERSION_25 }

        it 'does includes a date range as optional order parameter' do
          expect(order.to_xml).to include('<FDLOrderParams><DateRange><Start>2024-01-01</Start><End>2024-01-02</End></DateRange><FileFormat>camt.xxx.cfonb120.stm.Oby</FileFormat></FDLOrderParams>')
        end
      end
    end
  end

  context 'without file_format' do
    subject(:order) { described_class.new(client) }

    describe 'order attributes' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it { expect(subject.to_xml).to include('<OrderAttribute>DZHNN</OrderAttribute>') }
      it { expect(subject.to_xml).to include('<OrderType>FDL</OrderType>') }
    end

    include_examples '#to_xml'
    include_examples '#to_receipt_xml'

    describe '#to_xml' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it 'does not include a standard order parameter' do
        expect(order.to_xml).to include('<FDLOrderParams><FileFormat/></FDLOrderParams>')
      end
    end
  end
end

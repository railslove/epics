RSpec.describe Epics::FDL do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:file_format) { 'camt.xxx.cfonb120.stm.Oby' }

  context 'with file_format' do
    subject(:order) { described_class.new(client, file_format: file_format) }

    describe '#to_xml' do
      specify { expect(order.to_xml).to be_a_valid_ebics_25_doc }

      it 'does includes a date range as standard order parameter' do
        expect(order.to_xml).to include('<FDLOrderParams><FileFormat>camt.xxx.cfonb120.stm.Oby</FileFormat></FDLOrderParams>')
      end
    end

    describe '#to_receipt_xml' do
      before { order.transaction_id = SecureRandom.hex(16) }

      specify { expect(order.to_receipt_xml).to be_a_valid_ebics_25_doc }
    end

    context 'with DateRange' do
      subject(:order) { described_class.new(client, file_format: file_format, from: Date.new(2024, 1, 1), to: Date.new(2024, 1, 2)) }

      describe '#to_xml' do
        specify { expect(order.to_xml).to be_a_valid_ebics_25_doc }

        it 'does includes a date range as optional order parameter' do
          expect(order.to_xml).to include('<FDLOrderParams><DateRange><Start>2024-01-01</Start><End>2024-01-02</End></DateRange><FileFormat>camt.xxx.cfonb120.stm.Oby</FileFormat></FDLOrderParams>')
        end
      end

      describe '#to_receipt_xml' do
        before { order.transaction_id = SecureRandom.hex(16) }

        specify { expect(order.to_receipt_xml).to be_a_valid_ebics_25_doc }
      end
    end
  end

  context 'without file_format' do
    subject(:order) { described_class.new(client) }

    describe '#to_xml' do
      specify { expect(order.to_xml).to be_a_valid_ebics_25_doc }

      it 'does not include a standard order parameter' do
        expect(order.to_xml).to include('<FDLOrderParams><FileFormat/></FDLOrderParams>')
      end
    end

    describe '#to_receipt_xml' do
      before { order.transaction_id = SecureRandom.hex(16) }

      specify { expect(order.to_receipt_xml).to be_a_valid_ebics_25_doc }
    end
  end
end

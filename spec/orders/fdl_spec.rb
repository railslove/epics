RSpec.describe Epics::FDL do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  context 'with file format' do
    subject(:order) { described_class.new(client, "camt.fin.mt940.stm.0w1") }

    describe '#to_xml' do
      specify { expect(order.to_xml).to be_a_valid_ebics_doc }

      it 'does includes a file format as standard order parameter' do
        
        expect(order.to_xml).to include('<FDLOrderParams><FileFormat>camt.fin.mt940.stm.0w1</FileFormat></FDLOrderParams>')
      end
    end

    describe '#to_receipt_xml' do
      before { order.transaction_id = SecureRandom.hex(16) }

      specify { expect(order.to_receipt_xml).to be_a_valid_ebics_doc }
    end
  end

 
end

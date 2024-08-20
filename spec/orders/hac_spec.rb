RSpec.describe Epics::HAC do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  context 'with date range' do
    subject(:order) { described_class.new(client, from: "2014-09-01", to: "2014-09-30") }

    describe '#to_xml' do
      specify { expect(order.to_xml).to be_a_valid_ebics_doc }

      it 'does includes a date range as standard order parameter' do
        expect(order.to_xml).to include('<StandardOrderParams><DateRange><Start>2014-09-01</Start><End>2014-09-30</End></DateRange></StandardOrderParams>')
      end
    end

    describe '#to_receipt_xml' do
      before { order.transaction_id = SecureRandom.hex(16) }

      specify { expect(order.to_receipt_xml).to be_a_valid_ebics_doc }
    end
  end

  context 'without date range' do
    subject(:order) { described_class.new(client) }

    describe '#to_xml' do
      specify { expect(order.to_xml).to be_a_valid_ebics_doc }

      it 'does not include a standard order parameter' do
        expect(order.to_xml).to include('<StandardOrderParams/>')
      end
    end

    describe '#to_receipt_xml' do
      before { order.transaction_id = SecureRandom.hex(16) }

      specify { expect(order.to_receipt_xml).to be_a_valid_ebics_doc }
    end
  end
end

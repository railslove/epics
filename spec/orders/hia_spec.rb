RSpec.describe Epics::HIA do

  let(:client) { Epics::Client.new( File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key'), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  subject { described_class.new(client) }

  describe '#to_xml' do
    specify { expect(subject.to_xml).to be_a_valid_ebics_doc }

    describe 'validate against fixture' do

      let(:hia) { File.read File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'hia.xml') }

      it "will match exactly" do
        expect(subject.to_xml).to eq(hia)
      end
    end
  end

  describe '#order_data' do

    specify { expect(subject.order_data).to be_a_valid_ebics_doc }

    describe 'validate against fixture' do

      let(:hia_request_order_data) { File.read File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'hia_request_order_data.xml') }

      it "will match exactly" do
        expect(subject.order_data).to eq(hia_request_order_data)
      end
    end
  end

end

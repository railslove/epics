RSpec.describe Epics::HIA do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  subject { described_class.new(client) }

  describe '#to_xml' do
    specify { expect(subject.to_xml).to be_a_valid_ebics_25_doc }

    describe 'validate against fixture' do
      let(:hia) { Nokogiri::XML(File.read(File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', RUBY_ENGINE, 'hia.xml'))) }

      it "will match exactly" do
        expect(Nokogiri::XML(subject.to_xml)).to be_equivalent_to(hia)
      end
    end
  end

  describe '#order_data' do

    specify { expect(subject.order_data).to be_a_valid_ebics_25_doc }

    describe 'validate against fixture' do

      let(:hia_request_order_data) { Nokogiri::XML(File.read(File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'hia_request_order_data.xml'))) }

      it "will match exactly" do
        expect(Nokogiri::XML(subject.order_data)).to be_equivalent_to(hia_request_order_data)
      end
    end
  end
end

RSpec.describe Epics::INI do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  before { allow(subject).to receive(:timestamp) { "2014-10-10T11:16:00Z" } }

  subject { described_class.new(client) }

  describe '#to_xml' do
    specify { expect(subject.to_xml).to be_a_valid_ebics_doc }

    describe 'validate against fixture' do
      let(:signature_order_data) { Nokogiri::XML(File.read(File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', RUBY_ENGINE, 'ini.xml'))) }

      it "will match exactly" do
        expect(Nokogiri::XML(subject.to_xml)).to be_equivalent_to(signature_order_data)
      end
    end
  end

  describe '#key_signature' do
    specify { expect(subject.key_signature).to be_a_valid_ebics_doc }

    describe 'validate against fixture' do

      let(:signature_order_data) { Nokogiri::XML(File.read(File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'signature_pub_key_order_data.xml'))) }

      it "will match exactly" do
        expect(Nokogiri::XML(subject.key_signature)).to be_equivalent_to(signature_order_data)
      end
    end
  end
end

RSpec.describe Epics::FUL do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:document) { File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'cd1.xml') ) }

  subject { described_class.new(client, document, file_format: 'pain.001.001.02') }

  describe 'order attributes' do
    it { expect(subject.header.to_s).to include('<OrderAttribute>DZHNN</OrderAttribute>') }
    it { expect(subject.header.to_s).to include('<OrderType>FUL</OrderType>') }
    it { expect(subject.header.to_s).to include('<FileFormat>pain.001.001.02</FileFormat>') }
  end

  describe '#to_xml' do
    specify { expect(subject.to_xml).to be_a_valid_ebics_doc }
  end

  describe '#to_transfer_xml' do
    before { subject.transaction_id = SecureRandom.hex(16) }

    specify { expect(subject.to_transfer_xml).to be_a_valid_ebics_doc }
  end
end
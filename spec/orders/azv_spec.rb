RSpec.describe Epics::AZV do

  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:document) { 'DTAZV' }

  subject { described_class.new(client, document) }

  describe '#to_xml' do
    specify { expect(subject.to_xml).to be_a_valid_ebics_doc }
  end

  describe '#to_transfer_xml' do
    before { subject.transaction_id = SecureRandom.hex(16) }

    specify { expect(subject.to_transfer_xml).to be_a_valid_ebics_doc }
  end

end

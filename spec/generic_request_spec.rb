RSpec.describe Epics::GenericRequest do

  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  subject { described_class.new(client) }

  describe '#to_fetch_segment_xml' do
    before do
      subject.transaction_id = 'd8e8fca2dc0f896fd7cb4cb0031ba249'
      subject.segment_number = 1
    end
    specify { expect(subject.to_fetch_segment_xml).to be_a_valid_ebics_doc }
  end

end

RSpec.describe Epics::HAA do

  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  subject { described_class.new(client) }

  describe '#to_xml' do
    specify { expect(subject.to_xml).to be_a_valid_ebics_doc }
  end

end
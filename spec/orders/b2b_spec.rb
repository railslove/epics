RSpec.describe Epics::B2B do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:document) { File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'cd1.xml') ) }
  subject { described_class.new(client, document) }

  describe '#to_xml' do
    specify { expect(subject.to_xml).to be_a_valid_ebics_25_doc }
  end
end

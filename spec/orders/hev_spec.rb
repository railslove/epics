RSpec.describe Epics::HEV do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  let(:xsd) { Nokogiri::XML::Schema(File.open( File.join( File.dirname(__FILE__), '..', 'xsd', 'H000', 'ebics_hev.xsd') )) }
  let(:validator) { xsd.valid?(Nokogiri::XML(subject.to_xml)) }

  subject { described_class.new(client) }

  describe '#to_xml' do
    specify { expect(validator).to be_truthy }
  end
end

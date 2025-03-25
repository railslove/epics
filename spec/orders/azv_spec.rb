RSpec.describe Epics::AZV do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  let(:document) { 'DTAZV' }

  subject { described_class.new(client, document) }

  include_examples '#to_xml'
  include_examples '#to_transfer_xml'
end

RSpec.describe Epics::XE2 do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  let(:document) { File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'swiss_credit_transfer.xml') ) }

  subject { described_class.new(client, document) }

  include_examples '#to_xml'
  include_examples '#to_transfer_xml'
end

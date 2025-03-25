RSpec.describe Epics::Z53 do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }

  subject { described_class.new(client, from: "2014-09-01", to: "2014-09-30") }

  include_examples '#to_xml'
end

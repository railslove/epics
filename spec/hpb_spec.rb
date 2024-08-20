RSpec.describe Epics::HPB do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  describe '#to_xml' do
    subject { Nokogiri::XML.parse(described_class.new(client).to_xml) }

    specify do
      expect(subject.xpath("//xmlns:Timestamp").first.content).to_not be_nil
      expect(subject.xpath("//xmlns:Nonce").first.content).to_not be_nil
      expect(subject.xpath("//xmlns:HostID").first.content).to eq("SIZBN001")
      expect(subject.xpath("//xmlns:UserID").first.content).to eq("EBIX")
      expect(subject.xpath("//xmlns:PartnerID").first.content).to eq("EBICS")
    end
  end

end

RSpec.describe Epics::HPB do
  let(:client) { instance_double(Epics::Client, host_id: "HOST", user_id: "USER", partner_id: "PARTNER") }
  describe '#to_xml' do
    subject { Nokogiri::XML.parse(described_class.new(client).to_xml) }

    it 'foo' do
      expect(subject.xpath("//xmlns:Timestamp").first.content).to_not be_nil
      expect(subject.xpath("//xmlns:Nonce").first.content).to_not be_nil
      expect(subject.xpath("//xmlns:HostID").first.content).to eq("HOST")
      expect(subject.xpath("//xmlns:UserID").first.content).to eq("USER")
      expect(subject.xpath("//xmlns:PartnerID").first.content).to eq("PARTNER")
    end
  end

end

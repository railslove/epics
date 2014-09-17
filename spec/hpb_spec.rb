RSpec.describe Epics::HPB do
  let(:client) { instance_double(Epics::Client, host_id: "HOST", user_id: "USER", partner_id: "PARTNER") }
  subject { described_class.new(client) }
  describe '#to_xml' do
    before do
      allow(subject).to receive(:timestamp) { "" }
      allow(subject).to receive(:nonce) { "" }
    end

    it 'foo' do
      expect(Nokogiri::XML.parse(subject.to_xml).to_xml).to eq(Nokogiri::XML(File.open("spec/fixtures/xml/hpb.xml")).to_xml)
    end
  end

end

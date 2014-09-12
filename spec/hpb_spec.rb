RSpec.describe Epics::HPB do

  describe '#to_xml' do
    before do
      allow(subject).to receive(:timestamp) { "" }
      allow(subject).to receive(:nonce) { "" }
      allow(subject).to receive(:host) { "HOST" }
      allow(subject).to receive(:partner) { "PARTNER" }
      allow(subject).to receive(:user) { "USER" }
    end

    it 'foo' do
      expect(Nokogiri::XML.parse(subject.to_xml).to_xml).to eq(Nokogiri::XML(File.open("spec/fixtures/xml/hpb.xml")).to_xml)
    end
  end

end
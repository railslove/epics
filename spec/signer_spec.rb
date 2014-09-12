RSpec.describe Epics::Signer do
  let(:user_key) { Epics::Key.new('spec/fixtures/x002.pem') }
  let(:xml) { Epics::HPB.new }

  before do
    allow(xml).to receive(:nonce) { "014a82626a51ee1cab547bbaf18a13a0" }
    allow(xml).to receive(:timestamp) { "2014-09-09T09:33:12Z" }
    allow(xml).to receive(:host) { "HOST" }
    allow(xml).to receive(:partner) { "PARTNER" }
    allow(xml).to receive(:user) { "USER" }

    subject.digest!
    subject.sign!
  end

  subject { described_class.new(xml.to_xml, user_key) }

  describe '#digest!' do
    it 'creates a digest of the *[authorized=true] nodes' do
      expect(subject.digest_node.content).to eq("3PyIbUqImICMDMrzTvrc9pEnEIbgfg5xR386vCs3u7c=")
    end

    it 'bar' do
      expect(Epics::Response.new(subject.doc.to_xml, user_key, user_key).digest_valid?).to be(true)
    end
  end

  describe '#sign!' do
    it 'signs the complete ds:SignedInfo node' do
      expect(subject.doc.xpath("//ds:SignatureValue").first.content).to eq("M1/s3EXSqtNixa09HT6+TY1L71Ufl7qkhCG0cyMP5rQKNaBkOSKPVYDjycg5K0Ug80s2IBoqPac4AG1THi9+l3Cj7rdEsgePX0agNRuoTHm86gjHmsyqkjTc+O/AIANDlnPu2A+Aa+8TyY/I3/VpzAsBIxL7duG5JzQ8ao5bxFgMIZF12ZIVQ4Q+ybqnxilTAMZ0/aiTIp4RMuF4U0O7Opi0v+zuO5gELk1h12mazDrzPuE7uwUZAYbqieJ5Sux+wGohZLwKrwaH5tAvBDZ3IvGXfA+pwHfBrgAs8tK0WpjN1pojvLQr5u9wjI9i8ot3vZVJnXwu5SEtsLPumYIWYg==")
    end

    it 'bar' do
      expect(Epics::Response.new(subject.doc.to_xml, user_key, user_key).signature_valid?).to be(true)
    end
  end

end
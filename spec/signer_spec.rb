RSpec.describe Epics::Signer do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:hpb) { Epics::HPB.new(client) }

  before do
    allow(hpb).to receive(:nonce) { "014a82626a51ee1cab547bbaf18a13a0" }
    allow(hpb).to receive(:timestamp) { "2014-09-09T09:33:12Z" }
    subject.digest!
    subject.sign!
  end

  subject { described_class.new(client, hpb.to_xml) }

  describe '#digest!' do
    it 'creates a digest of the *[authorized=true] nodes' do
      expect(subject.digest_node.content).to eq("iXchWJ3xMy508YBhzx0Fn9cYNyyAiS+X8CB8zb7tyfM=")
    end

    it 'bar' do
      expect(Epics::Response.new(client, subject.doc.to_xml(save_with: 32)).digest_valid?).to be(true)
    end
  end

  describe '#sign!' do
    it 'signs the complete ds:SignedInfo node' do
      expect(subject.doc.xpath("//ds:SignatureValue").first.content).to eq("o6G7zeU6IhEkQ51Mp5/aIhPcYiZAG1rERxFad+rVdbRCYJGUn6/BNath1cdTgoHQ+ZWn9+Y6IgFsKUYFp8QHrhYBJNhd38fi5wj2Eqv+J4nsfmSD9x6YFa8Q13cJ9/CakHp/C59bgFSJj77BzRFUPnW1Y1NuHj8n1OJ3iFTyF1vF6H6oRKHoE4cbK4jhD3f6udRvGglhW5J+TUFBM+2aE8njpzBZFjyQlct+5XUx3o+1GvaMUk5riH5sCQ95PAKuGTXFu0OLZvECDMA3kOia/l3VF09QUGsjxYF0jUn5WG6TnLy8+Odrh9tUgV9bS/swSeQ41Cah4Ehb0qTYFZoJ+w==")
    end

    it 'can be verified with the same key' do
      expect(client.authentication_key.verify(subject.doc.xpath("//ds:SignatureValue").first.content, subject.signature_node.canonicalize)).to be(true)
    end
  end

end

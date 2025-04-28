RSpec.describe Epics::Handlers::AuthSignatureHandler do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:hpb) { Epics::HPB.new(client) }

  before { allow(SecureRandom).to receive(:hex).with(16).and_return('014a82626a51ee1cab547bbaf18a13a0') }
  before { allow(Time).to receive(:now).and_return(Time.parse('2014-09-09T09:33:12Z')) }

  subject { Nokogiri::XML(hpb.to_xml) }
  let(:headers_node) { subject.xpath("//*[@authenticate='true']").first }
  let(:crypt_service) { Epics::Services::CryptService.new }
  let(:header_hash) { crypt_service.hash(headers_node.canonicalize) }
  let(:digest_node) { subject.xpath('//ds:DigestValue', ds: 'http://www.w3.org/2000/09/xmldsig#').first }
  let(:signature_value_node) { subject.xpath('//ds:SignatureValue', ds: 'http://www.w3.org/2000/09/xmldsig#').first }
  let(:signature_node) { subject.xpath('//ds:SignedInfo', ds: 'http://www.w3.org/2000/09/xmldsig#').first }

  describe '#digest!' do
    it 'creates a digest of the *[authorized=true] nodes' do
      expect(digest_node.content).to eq('iXchWJ3xMy508YBhzx0Fn9cYNyyAiS+X8CB8zb7tyfM=')
    end

    it 'bar' do
      expect(digest_node.content).to eq(Base64.strict_encode64(header_hash))
    end
  end

  describe '#sign!' do
    it 'signs the complete ds:SignedInfo node' do
      expect(signature_value_node.content).to eq('o6G7zeU6IhEkQ51Mp5/aIhPcYiZAG1rERxFad+rVdbRCYJGUn6/BNath1cdTgoHQ+ZWn9+Y6IgFsKUYFp8QHrhYBJNhd38fi5wj2Eqv+J4nsfmSD9x6YFa8Q13cJ9/CakHp/C59bgFSJj77BzRFUPnW1Y1NuHj8n1OJ3iFTyF1vF6H6oRKHoE4cbK4jhD3f6udRvGglhW5J+TUFBM+2aE8njpzBZFjyQlct+5XUx3o+1GvaMUk5riH5sCQ95PAKuGTXFu0OLZvECDMA3kOia/l3VF09QUGsjxYF0jUn5WG6TnLy8+Odrh9tUgV9bS/swSeQ41Cah4Ehb0qTYFZoJ+w==')
    end

    it 'can be verified with the same key' do
      expect(client.keyring.user_authentication.key.verify(signature_value_node.content, signature_node.canonicalize)).to be(true)
    end
  end

end

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
      expect(digest_node.content).to eq('j0WiGMS9D6Bt1xw92ZAOWUsAJ+OBlUYKtHRQI7TbpbY=')
    end

    it 'bar' do
      expect(digest_node.content).to eq(Base64.strict_encode64(header_hash))
    end
  end

  describe '#sign!' do
    it 'signs the complete ds:SignedInfo node' do
      expect(signature_value_node.content).to eq('K3FNqdg90AoFqgc1bM2CgAKHNfy7SWWcrm03CXEfu9XF4q4/2QWRyOAShcoF+kG60lnKjADqMqLTpMqXMTKg2AX9IItdl3p8IDocaZ4fVBdL8yUvE4/iH9569oj8QX4gvndwwS46TRVVYyZno1l44r9aEuUfaaqATp3ITQcyM3xDXFsNwVdJuUjzYHPTEOMXGxZlD/wIcLTQwMLLn0D/gitgsXQKqvGH3VI80bAG7aIxmLpcPEBqrAaZGCIghZWvJK2CBfgjSstcdmIK5YRCYF5UjCqoEywnp8ELaFtWMTcLPtq0GfJ1e84vGCVSNRdIH30dNRKINDWl+4YtzJpa5A==')
    end

    it 'can be verified with the same key' do
      expect(client.keyring.user_authentication.key.verify(signature_value_node.content, signature_node.canonicalize)).to be(true)
    end
  end

end

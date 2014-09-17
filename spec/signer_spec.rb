RSpec.describe Epics::Signer do
  let(:client) { Epics::Client.new( File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key'), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
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
      expect(subject.digest_node.content).to eq("frPojdWbSHdC2wM+sdFl3ojIX1XBtSheG8naY7kq6IY=")
    end

    it 'bar' do
      expect(Epics::Response.new(client, subject.doc.to_xml).digest_valid?).to be(true)
    end
  end

  describe '#sign!' do
    it 'signs the complete ds:SignedInfo node' do
      expect(subject.doc.xpath("//ds:SignatureValue").first.content).to eq("h03qEZmhKvJPHWAMkrjxGA/IWcNrubszI+F/uA710QmCj9DQwDJ2QD1NRdS+yAkhoyfv0NMpk3TXyfnieqQ9LpgVYJJVZKpuxO4mWX+YZi5rVi7CRzO3VeIH8sUSCHtw++tdzWHpNjZwgOsMqJ8LJoBuH+2dtsPMw9aBliz9CHViVpumSMKNXqeJlyypIJYSmAL8z+i5ekVXSEGMkZhO1iTSDmDSQdCIJPGwIJd0llVBPMztE3tN269aXZC4Slgk7UVtLfAYupr5RZOEV7KlFrSo1zDe/VQaJitlVtVYPBIpfWkLCJ1pq7Re3q4Y0eXf1FuU+5A3XOqyFa2S6oxW1A==")
    end

    it 'can be verified with the same key' do
      expect(client.x.key.verify(OpenSSL::Digest::SHA256.new, Base64.decode64(subject.doc.xpath("//ds:SignatureValue").first.content), subject.signature_node.canonicalize)).to be(true)
    end
  end

end

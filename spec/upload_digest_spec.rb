RSpec.describe 'upload order data digests' do
  let(:key_file) { File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')) }
  let(:document) { File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml', 'cd1.xml')) }
  let(:client) do
    Epics::Client.new(key_file, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb',
                      'SIZBN001', 'EBIX', 'EBICS', version:)
  end

  describe '#document_digest' do
    let(:version) { Epics::Keyring::VERSION_25 }

    subject { Epics::CCT.new(client, document) }

    # Pinned: the hash basis determines the ES for every upload.
    it 'hashes the document with CR and LF removed' do
      expect(subject.document_digest)
        .to eq(OpenSSL::Digest.digest('sha256', document.gsub(/\n|\r/, '')))
    end

    it 'does not hash the raw document' do
      expect(subject.document_digest)
        .not_to eq(OpenSSL::Digest.digest('sha256', document))
    end

    # Hashed bytes must equal transmitted bytes.
    it 'normalizes once, so the digest covers exactly what is transmitted' do
      expect(subject.document).not_to include("\n")
      expect(subject.document_digest)
        .to eq(OpenSSL::Digest.digest('sha256', subject.document))
    end

    it 'is identical for CRLF and LF encodings of the same document' do
      lf   = "<Doc>\n  <A>1</A>\n</Doc>"
      crlf = "<Doc>\r\n  <A>1</A>\r\n</Doc>"

      expect(Epics::CCT.new(client, crlf).document_digest)
        .to eq(Epics::CCT.new(client, lf).document_digest)
    end
  end

  describe 'H005 DataDigest' do
    let(:version) { Epics::Keyring::VERSION_30 }
    let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

    def data_digest_of(order)
      Nokogiri::XML(order.to_xml).at_xpath('//e:DataDigest', ns)
    end

    # EBICS 3.0.2 §5.5.1.1: DataDigest is the "Hashwert der Auftragsdaten";
    # @SignatureVersion names the hash algorithm, not a signature.
    it 'carries the SHA-256 hash of the order data, not a signature' do
      order = Epics::CCT.new(client, document)

      expect(Base64.decode64(data_digest_of(order).text).bytesize).to eq(32)
      expect(Base64.strict_encode64(order.document_digest))
        .to eq(data_digest_of(order).text)
    end

    it 'is reproducible across two builds of the same document' do
      expect(data_digest_of(Epics::CCT.new(client, document)).text)
        .to eq(data_digest_of(Epics::CCT.new(client, document)).text)
    end

    it 'names the signature version used to form it' do
      expect(data_digest_of(Epics::CCT.new(client, document))['SignatureVersion'])
        .to eq(client.keyring.user_signature.version)
    end
  end
end

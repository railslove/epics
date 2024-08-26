RSpec.describe Epics::GenericUploadRequest do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:document) { "\x01" * 12 }
  subject { described_class.new(client, document) }

  describe '#pad' do

    it 'will complete the block to the next 16byte' do
      expect(subject.pad("\x01" * 13).size).to eq(16)
    end

    it 'will pad a complete block if the size is a multiple of 16' do
      expect(subject.pad("\x01" * 16).size).to eq(32)
    end

    it 'will set the last byte to the padding length' do
      expect(subject.pad("\x01" * 13)[-1]).to eq([3].pack("C*"))
    end
  end

  describe '#signature_value' do
    before { allow(OpenSSL::Random).to receive(:random_bytes).with(16).and_return("\x01" * 16) } # fake random_key requires a 16byte lenght but is not used in this test
    before { allow(OpenSSL::Random).to receive(:random_bytes).with(32).and_return(Base64.strict_decode64("7wtROfiX4tyN60cygJUSsHkhzxX1RVJa8vGNYnflvKc=")) } # digest requires 32 bytes

    it 'will be the signed document' do
      verification_result = subject.client.signature_key.verify(subject.signature_value, OpenSSL::Digest::SHA256.new.digest(document))

      expect(verification_result).to eq(true)
    end
  end

  describe '#order_signature' do
    before { allow(subject).to receive(:signature_value).and_return("FOOBAR") }
    let(:signature) { Nokogiri::XML(subject.order_signature) }

    it 'contains the untouched signature_value ' do
      expect(signature.at_xpath('//xmlns:SignatureValue').text).to eq("FOOBAR")
    end

  end

  describe '#encrypted_order_data' do
    it 'returns the same data every time' do
      data_1 = subject.encrypted_order_data
      data_2 = subject.encrypted_order_data

      expect(data_1).to eq(data_2)
    end
  end
end

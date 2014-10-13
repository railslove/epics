RSpec.describe Epics::Response do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  subject { described_class.new( client, File.read('spec/fixtures/xml/upload_init_response.xml') ) }

  describe '#digest_valid?' do
    it 'checks if //ds:DigestValue matches the calculated digest' do
      expect(subject.digest_valid?).to be(true)
    end
  end

  describe '#signature_valid?' do
    it 'checks if the signature value can be verified with the bank key' do
      expect(subject.signature_valid?).to be(true)
    end
  end

  describe '#public_digest_valid?' do
    subject { described_class.new( client, File.read('spec/fixtures/xml/hpb_response.xml') ) }

    it "checks if //xmlns:EncryptionPubKeyDigest matches the user encryption key" do
      expect(subject.public_digest_valid?).to be(true)
    end
  end

  describe 'order_data' do
    let(:order_data) { File.read('spec/fixtures/xml/hpb_response_order.xml') }
    subject { described_class.new( client, File.read('spec/fixtures/xml/hpb_response.xml') ) }

    it "retrieves the decrypted order data" do
      expect(subject.order_data).to eq(order_data)
    end
  end

end

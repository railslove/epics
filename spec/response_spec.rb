RSpec.describe Epics::Response do

  let(:bank_key) { Epics::Key.new('spec/fixtures/bank_e.pem') }
  let(:user_key) { Epics::Key.new('spec/fixtures/e002.pem') }

  subject { described_class.new( File.read('spec/fixtures/xml/upload_init_response.xml'), user_key, bank_key ) }

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
    subject { described_class.new( File.read('spec/fixtures/xml/hpb_response.xml'), user_key, bank_key ) }

    it "checks if //xmlns:EncryptionPubKeyDigest matches the user encryption key" do
      expect(subject.public_digest_valid?).to be(true)
    end
  end

  describe 'order_data' do
    let(:order_data) { File.read('spec/fixtures/xml/hpb_response_order.xml') }
    subject { described_class.new( File.read('spec/fixtures/xml/hpb_response.xml'), user_key, bank_key ) }

    it "retrieves the decrypted order data" do
      expect(subject.order_data).to eq(order_data)
    end
  end

end
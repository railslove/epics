RSpec.describe Epics::Response do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  subject { described_class.new( client, ebics_response ) }

  describe '#digest_valid?' do
    let(:ebics_response) { File.read('spec/fixtures/xml/upload_init_response.xml') }

    it 'checks if //ds:DigestValue matches the calculated digest' do
      expect(subject.digest_valid?).to be(true)
    end
  end

  describe '#signature_valid?' do
    let(:ebics_response) { File.read('spec/fixtures/xml/upload_init_response.xml') }

    it 'checks if the signature value can be verified with the bank key' do
      expect(subject.signature_valid?).to be(true)
    end
  end

  describe '#public_digest_valid?' do
    let(:ebics_response) { File.read('spec/fixtures/xml/hpb_response.xml') }

    it "checks if //xmlns:EncryptionPubKeyDigest matches the user encryption key" do
      expect(subject.public_digest_valid?).to be(true)
    end
  end

  describe 'order_data' do
    let(:ebics_response) { File.read('spec/fixtures/xml/hpb_response.xml') }
    let(:order_data) { File.read('spec/fixtures/xml/hpb_response_order.xml') }

    it "retrieves the decrypted order data" do
      expect(subject.order_data).to eq(order_data)
    end
  end

  describe '#transaction_id' do
    let(:ebics_response) { File.read('spec/fixtures/xml/sta_response.xml') }
    it 'pulls the transaction_id from the response' do
      expect(subject.transaction_id).to eq('ECD6F062AAEDFA77250526A68CBEC549')
    end
  end

  describe '#last_segment?' do
    describe 'when its the last segement' do
      let(:ebics_response) { File.read('spec/fixtures/xml/sta_response.xml') }

      it 'will be true' do
        expect(subject.last_segment?).to be(true)
      end
    end

    describe 'when there are more segments' do
      let(:ebics_response) { File.read('spec/fixtures/xml/sta_response_continued.xml') }
      it 'will be false' do
        expect(subject.last_segment?).to be(false)
      end
    end
  end

  describe '#segmented?' do
    describe 'when the response is segemnted' do
      let(:ebics_response) { File.read('spec/fixtures/xml/sta_response.xml') }

      it 'will be true' do
        expect(subject.segmented?).to be(true)
      end
    end

    describe 'when the response is not segemnted' do
      let(:ebics_response) { File.read('spec/fixtures/xml/hpb_response.xml') }

      it 'will be false' do
        expect(subject.segmented?).to be(false)
      end
    end
  end

end

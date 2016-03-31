RSpec.describe Epics::HVS do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:digest) { Base64.strict_encode64("supersecretdigest") }

  subject { described_class.new(client, "myid", "mytype", digest) }

  describe '#segmented?' do
    it 'returns false' do
      expect(subject.segmented?).to eq(false)
    end
  end

  describe '#to_xml' do
    describe 'message header' do
      it 'sets order type' do
        expect(subject.to_xml).to include("<OrderType>HVS</OrderType>")
      end

      it 'uploads as order without segments' do
        expect(subject.to_xml).to include("<OrderAttribute>UZHNN</OrderAttribute>")
      end

      it 'sets order params' do
        expect(subject.to_xml).to include("<HVSOrderParams>")
      end

      it 'sets number of segments to zero' do
        expect(subject.to_xml).to include("<NumSegments>0</NumSegments>")
      end
    end

    describe 'message body' do
      it 'includes a signature' do
        expect(subject.to_xml).to include("<SignatureData authenticate=\"true\">")
      end

      it 'does not have any order data' do
        expect(subject.to_xml).to_not include("<OrderData>")
      end
    end
  end
end

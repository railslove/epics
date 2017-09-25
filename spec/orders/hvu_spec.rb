require 'spec_helper'

RSpec.describe Epics::HVU do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  describe 'No data available' do
    before { allow(client).to receive(:download).with(described_class).and_raise(Epics::Error::BusinessError, "090005") }

    it 'returns an empty array'
  end

  describe 'data is available' do
    let(:xml_response) { File.read(File.join(File.dirname(__FILE__), '../fixtures/xml/hvu_response.xml')) }

    before { allow(client).to receive(:download).with(described_class).and_return(xml_response) }

    it 'parses and returns an array' do
      expect(client.HVU).to be_instance_of(Array)
    end

    it 'parses and returns each order' do
      expect(client.HVU.size).to eq(2)
    end

    describe 'attributes' do
      subject { client.HVU.first }

      it 'sets the order id' do
        expect(subject[:order_id]).to eq('B03N')
      end

      it 'sets order type' do
        expect(subject[:order_type]).to eq('CCT')
      end

      it 'lists all signers' do
        expect(subject[:signers]).to be_instance_of(Array)
      end

      it 'sets the originator' do
        expect(subject[:originator]).to match(hash_including(
          :name => "RS T",
          :partner_id => "RS",
          :timestamp => Time.new(2016, 3, 23, 8, 56, 39, "+00:00"),
          :user_id => "RST",
        ))
      end

      it 'sets flag if ready to be signed' do
        expect(subject[:ready_for_signature]).to eq(true)
      end

      it 'sets number of already applied signatures' do
        expect(subject[:applied_signatures]).to eq(1)
      end

      it 'sets number of required signatures' do
        expect(subject[:required_signatures]).to eq(1)
      end

      it 'does not have total_amount' do
        expect(subject).to_not have_key(:total_amount)
      end

      it 'does not have total_amount_type' do
        expect(subject).to_not have_key(:total_amount_type)
      end

      it 'does not have total_orders' do
        expect(subject).to_not have_key(:total_orders)
      end

      it 'does not have digest' do
        expect(subject).to_not have_key(:digest)
      end

      it 'does not have digest_signature_version' do
        expect(subject).to_not have_key(:digest_signature_version)
      end
    end

  end

end

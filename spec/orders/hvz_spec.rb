require 'spec_helper'

RSpec.describe Epics::HVZ do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  describe 'No data available' do
    before { allow(client).to receive(:download).with(Epics::HVZ).and_raise(Epics::Error::BusinessError, "090005") }

    it 'returns an empty array'
  end

  describe 'data is available' do
    let(:xml_response) { File.read(File.join(File.dirname(__FILE__), '../fixtures/xml/hvz_response.xml')) }

    before { allow(client).to receive(:download).with(Epics::HVZ).and_return(xml_response) }

    it 'parses and returns an array' do
      expect(client.HVZ).to be_instance_of(Array)
    end

    it 'parses and returns each order' do
      expect(client.HVZ.size).to eq(2)
    end

    describe 'attributes' do
      subject { client.HVZ.first }

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

      it 'sets total_amount' do
        expect(subject[:total_amount]).to eq(1000.13)
      end
      it 'sets total_amount_type' do
        expect(subject[:total_amount_type]).to eq('credit')
      end

      it 'sets total_orders' do
        expect(subject[:total_orders]).to eq(1)
      end

      it 'sets digest' do
        expect(subject[:digest]).to eq('Ej9Q5zvpef87V9Ef5vdEY/aiPvEiVYupcZHir51G94g=')
      end

      it 'sets digest_signature_version' do
        expect(subject[:digest_signature_version]).to eq('A006')
      end
    end

  end

end

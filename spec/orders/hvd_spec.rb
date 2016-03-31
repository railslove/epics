require 'spec_helper'

RSpec.describe Epics::HVD do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  describe 'No data available' do
    it 'returns nil'
  end

  describe 'data is available' do
    let(:xml_response) { File.read(File.join(File.dirname(__FILE__), '../fixtures/xml/hvd_response.xml')) }

    before { allow(client).to receive(:download).with(described_class, 'B03N', 'CCT').and_return(xml_response) }

    describe 'attributes' do
      subject { client.HVD('B03N', 'CCT') }

      it 'lists all signers' do
        expect(subject[:signers]).to be_instance_of(Array)
      end

      it 'indicates if detailed order data is available' do
        expect(subject[:order_details_available]).to eq(false)
      end

      it 'indicates if order data is available' do
        expect(subject[:order_data_available]).to eq(true)
      end

      it 'sets correct string encoding' do
        expect(subject[:display_file]).to include("Ausführungstermin")
      end

      it 'indicates if order data is available' do
        expect(subject[:display_file]).to include("Datei-ID")
      end

      it 'sets digest' do
        expect(subject[:digest]).to eq('Ej9Q5zvpef87V9Ef5vdEY/aiPvEiVYupcZHir51G94g=')
      end

      it 'sets digest_signature_version' do
        expect(subject[:digest_signature_version]).to eq('A006')
      end

      it 'does not include an order id' do
        expect(subject).to_not have_key(:order_id)
      end

      it 'does not include an order type' do
        expect(subject).to_not have_key(:order_type)
      end

      it 'does not include an originator' do
        expect(subject).to_not have_key(:originator)
      end

      it 'does not include flag if ready to be signed' do
        expect(subject).to_not have_key(:ready_for_signature)
      end

      it 'does not include number of already applied signatures' do
        expect(subject).to_not have_key(:applied_signatures)
      end

      it 'does not include number of required signatures' do
        expect(subject).to_not have_key(:required_signatures)
      end

      it 'does not include not have total_amount' do
        expect(subject).to_not have_key(:total_amount)
      end

      it 'does not have total_amount_type' do
        expect(subject).to_not have_key(:total_amount_type)
      end

      it 'does not have total_orders' do
        expect(subject).to_not have_key(:total_orders)
      end
    end
  end
end

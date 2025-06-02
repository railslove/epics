# frozen_string_literal: true

RSpec.describe Epics::ParseEbics do
  let(:key) { File.read('spec/fixtures/SIZBN001.key') }
  let(:base_client_params) do
    [key, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS']
  end

  let(:version) { Epics::Keyring::VERSION_25 }
  let(:client) { Epics::Client.new(*base_client_params, { version: version }) }

  let(:faraday_stubs) do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post('/business_nok') do
        [200, {}, fixture_content('xml/ebics_business_nok.xml')]
      end
      stub.post('/technical_nok') do
        [200, {}, fixture_content('xml/ebics_technical_nok.xml')]
      end
      stub.post('/ok') do
        [200, {}, fixture_content('xml/hpb_response_ebics_ns.xml')]
      end
      stub.post('/timeout') { raise Faraday::TimeoutError }
      stub.post('/no_connection') do
        raise Faraday::ConnectionFailed, 'peer has finished all lan parties and gone home'
      end
    end
  end

  subject(:faraday_client) do
    Faraday.new do |builder|
      builder.use described_class, client: client
      builder.adapter :test, faraday_stubs
    end
  end

  describe 'error handling' do
    it 'raises BusinessError for business-related errors' do
      expect { faraday_client.post('/business_nok') }
        .to raise_error(
          Epics::Error::BusinessError,
          'EBICS_PROCESSING_ERROR - During processing of the EBICS request, other business-related errors have ocurred'
        )
    end

    it 'raises TechnicalError for technical errors' do
      expect { faraday_client.post('/technical_nok') }
        .to raise_error(
          Epics::Error::TechnicalError,
          'EBICS_AUTHENTICATION_FAILED - Authentication signature error'
        )
    end
  end

  describe 'successful response parsing' do
    let(:response) { faraday_client.post('/ok') }

    it 'parses response body as Epics::Response' do
      expect(response.body).to be_an(Epics::Response)
    end

    it 'passes client to Epics::Response constructor' do
      allow(Epics::Response).to receive(:new).and_call_original

      response

      expect(Epics::Response).to have_received(:new).with(client, anything)
    end
  end

  describe 'network failures' do
    it 'propagates Faraday::TimeoutError' do
      expect { faraday_client.post('/timeout') }
        .to raise_error(Faraday::TimeoutError, 'timeout')
    end

    it 'propagates Faraday::ConnectionFailed' do
      expect { faraday_client.post('/no_connection') }
        .to raise_error(
          Faraday::ConnectionFailed,
          'peer has finished all lan parties and gone home'
        )
    end
  end

  describe 'version-specific behavior' do
    context 'when using H003 version (VERSION_24)' do
      let(:version) { Epics::Keyring::VERSION_24 }

      let(:h003_stubs) do
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post('/fdl_h003_cd') do
            [200, {}, fixture_content('xml/fdl_no_data-response_h003_ns.xml')]
          end
        end
      end

      subject(:h003_client) do
        Faraday.new do |builder|
          builder.use described_class, client: client
          builder.adapter :test, h003_stubs
        end
      end

      it 'handles FDL request with no data available' do
        expect { h003_client.post('/fdl_h003_cd') }
          .to raise_error(
            Epics::Error::TechnicalError,
            'EBICS_NO_DOWNLOAD_DATA_AVAILABLE - No data are available at present for the selected download order type'
          )
      end
    end
  end

  describe 'middleware integration' do
    it 'processes response through complete middleware chain' do
      response = faraday_client.post('/ok')

      expect(response).to be_success
      expect(response.body).to respond_to(:technical_error?)
      expect(response.body).to respond_to(:business_error?)
    end
  end

  private

  def fixture_content(path)
    File.read(File.join('spec', 'fixtures', path))
  end
end

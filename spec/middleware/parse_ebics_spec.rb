# frozen_string_literal: true

RSpec.describe Epics::ParseEbics do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'HOST', 'USER', 'PARTNER') }
  let(:maintenance_page) do
    <<~HTML
      <html><head><title>503 Service Unavailable</title></head><body>
      <h1>Service Unavailable</h1>
      <p>The server is temporarily unable to service your request due to maintenance downtime.</p>
      </body></html>
    HTML
  end

  let(:stubs) do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post('/business_nok') { [200, {}, File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'ebics_business_nok.xml'))] }
      stub.post('/technical_nok') { [200, {}, File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'ebics_technical_nok.xml'))] }
      stub.post('/ok') { [200, {}, File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'hpb_response_ebics_ns.xml'))] }
      stub.post('/timeout') { raise Faraday::TimeoutError }
      stub.post('/no_connection') { raise Faraday::ConnectionFailed, 'peer has finished all lan parties and gone home' }
    end
  end

  subject do
    Faraday.new do |builder|
      builder.use Epics::ParseEbics, { client: client }
      builder.adapter :test, stubs
    end
  end

  it 'will handle errornous response with raising the related error class' do
    expect { subject.post('/business_nok') }.to raise_error(Epics::Error::BusinessError, 'EBICS_PROCESSING_ERROR - During processing of the EBICS request, other business-related errors have ocurred')
    expect { subject.post('/technical_nok') }.to raise_error(Epics::Error::TechnicalError, 'EBICS_AUTHENTICATION_FAILED - Authentication signature error')
  end

  it 'will parsed as Epics::Response' do
    expect(subject.post('/ok').body).to be_kind_of(Epics::Response)
  end

  context 'when the bank answers with a non-2xx status' do
    it 'raises an HTTPError carrying the status and the start of the body' do
      stubs.post('/') { [503, { 'Content-Type' => 'text/html' }, maintenance_page] }

      expect { subject.post('/') }.to raise_error(Epics::Error::HTTPError, 'HTTP 503 Service Unavailable') do |error|
        expect(error.status).to eq(503)
        expect(error.body).to include('maintenance downtime')
      end
    end

    it 'raises an HTTPError for an empty body' do
      stubs.post('/') { [502, {}, ''] }

      expect { subject.post('/') }.to raise_error(Epics::Error::HTTPError, 'HTTP 502 Bad Gateway') do |error|
        expect(error.status).to eq(502)
        expect(error.body).to eq('')
      end
    end

    it 'raises an HTTPError for a 500 that carries an EBICS response, keeping its return code only in the excerpt' do
      ebics_technical_nok = File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'ebics_technical_nok.xml'))
      stubs.post('/') { [500, {}, ebics_technical_nok] }

      expect { subject.post('/') }.to raise_error(Epics::Error::HTTPError, 'HTTP 500 Internal Server Error') do |error|
        expect(error.code).to be_nil
        expect(error.body).to include('<ReturnCode>061001</ReturnCode>')
      end
    end

    it 'can be rescued as an Epics::Error but not as a TechnicalError' do
      stubs.post('/') { [503, { 'Content-Type' => 'text/html' }, maintenance_page] }

      expect { subject.post('/') }.to raise_error(Epics::Error) do |error|
        expect(error).not_to be_a(Epics::Error::TechnicalError)
      end
    end
  end

  context 'at the edges of the 2xx range' do
    it 'raises an HTTPError for 199' do
      stubs.post('/') { [199, {}, ''] }

      expect { subject.post('/') }.to raise_error(Epics::Error::HTTPError, 'HTTP 199')
    end

    it 'raises an InvalidResponseError for a 204 without a body' do
      stubs.post('/') { [204, {}, ''] }

      expect { subject.post('/') }
        .to raise_error(Epics::InvalidResponseError, "Could not read ReturnCode from the bank's response")
    end

    it 'parses a 299 as an EBICS response' do
      hpb_response = File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'hpb_response_ebics_ns.xml'))
      stubs.post('/') { [299, {}, hpb_response] }

      expect(subject.post('/').body).to be_a(Epics::Response)
    end

    it 'raises an HTTPError for 300' do
      stubs.post('/') { [300, {}, ''] }

      expect { subject.post('/') }.to raise_error(Epics::Error::HTTPError, 'HTTP 300')
    end
  end

  context 'when a 2xx body carries no EBICS ReturnCode' do
    it 'raises an InvalidResponseError carrying the start of the body' do
      stubs.post('/') { [200, { 'Content-Type' => 'text/plain' }, 'Welcome to the bank portal'] }

      expect { subject.post('/') }
        .to raise_error(Epics::InvalidResponseError, "Could not read ReturnCode from the bank's response") do |error|
        expect(error.field).to eq('ReturnCode')
        expect(error.body).to eq('Welcome to the bank portal')
        expect(error).not_to respond_to(:status)
      end
    end

    it 'raises an InvalidResponseError for an empty body' do
      stubs.post('/') { [200, {}, ''] }

      expect { subject.post('/') }.to raise_error(Epics::InvalidResponseError) do |error|
        expect(error.body).to eq('')
        expect(error).not_to be_a(Epics::Error::TechnicalError)
      end
    end

    it 'raises an InvalidResponseError for an EBICS document cut off before its ReturnCode' do
      stubs.post('/') { [200, {}, '<ebicsResponse xmlns="urn:org:ebics:H004"><header authenticate="true"><static>'] }

      expect { subject.post('/') }.to raise_error(Epics::InvalidResponseError) do |error|
        expect(error.body).to start_with('<ebicsResponse')
      end
    end
  end

  context 'failures' do
    it 'will raise a timeout correctly' do
      expect { subject.post('/timeout') }.to raise_error(Faraday::TimeoutError, 'timeout')
    end

    it 'will properly raise non-epics errors' do
      expect { subject.post('/no_connection') }.to raise_error(Faraday::ConnectionFailed, 'peer has finished all lan parties and gone home')
    end
  end
end

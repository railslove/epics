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
        expect(error.body_excerpt).to include('maintenance downtime')
      end
    end

    it 'raises an HTTPError for an empty body' do
      stubs.post('/') { [502, {}, ''] }

      expect { subject.post('/') }.to raise_error(Epics::Error::HTTPError, 'HTTP 502 Bad Gateway') do |error|
        expect(error.status).to eq(502)
        expect(error.body_excerpt).to eq('')
      end
    end

    it 'raises an HTTPError for a 500 that carries an EBICS response, keeping its return code only in the excerpt' do
      ebics_technical_nok = File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'ebics_technical_nok.xml'))
      stubs.post('/') { [500, {}, ebics_technical_nok] }

      expect { subject.post('/') }.to raise_error(Epics::Error::HTTPError, 'HTTP 500 Internal Server Error') do |error|
        expect(error.code).to be_nil
        expect(error.body_excerpt).to include('<ReturnCode>061001</ReturnCode>')
      end
    end

    it 'raises an HTTPError for a redirect, the usual sign of a wrong bank URL' do
      stubs.post('/') { [302, { 'Location' => 'https://bank.example/login' }, ''] }

      expect { subject.post('/') }.to raise_error(Epics::Error::HTTPError, 'HTTP 302 Found')
    end

    it 'still raises the HTTPError when the request body is not XML, but not as retryable' do
      stubs.post('/') { [503, { 'Content-Type' => 'text/html' }, maintenance_page] }

      expect { subject.post('/', '<<not xml') }.to raise_error(Epics::Error::HTTPError) do |error|
        expect(error.phase).to be_nil
        expect(error.order_type).to be_nil
        expect(error).not_to be_retryable
      end
    end

    it 'is not retryable when the request is XML but not EBICS' do
      stubs.post('/') { [503, {}, ''] }

      expect { subject.post('/', '<order><amount>100</amount></order>') }.to raise_error(Epics::Error::HTTPError) do |error|
        expect(error).not_to be_retryable
      end
    end

    it 'is not retryable when the order data of an upload was sent as an IO, which it cannot read' do
      stubs.post('/') { [504, {}, ''] }
      upload = Epics::CCT.new(client, 'pain.001 document').tap { |order| order.transaction_id = 'B5F1A3D2C4E6F8091A2B3C4D5E6F7A8B' }

      expect { subject.post('/', StringIO.new(upload.to_transfer_xml)) }.to raise_error(Epics::Error::HTTPError) do |error|
        expect(error.phase).to be_nil
        expect(error).not_to be_retryable
      end
    end

    it 'reads the order data of a request in another EBICS namespace than the client uses' do
      stubs.post('/') { [504, {}, ''] }
      transfer = '<ebicsRequest xmlns="urn:org:ebics:H005"><header><mutable><TransactionPhase>Transfer</TransactionPhase>' \
                 '</mutable></header><body><DataTransfer><OrderData>data</OrderData></DataTransfer></body></ebicsRequest>'

      expect { subject.post('/', transfer) }.to raise_error(Epics::Error::HTTPError) do |error|
        expect(error.phase).to eq('Transfer')
        expect(error).not_to be_retryable
      end
    end

    it 'can be rescued as an Epics::Error but not as a TechnicalError' do
      stubs.post('/') { [503, { 'Content-Type' => 'text/html' }, maintenance_page] }

      expect { subject.post('/') }.to raise_error(Epics::Error) do |error|
        expect(error).not_to be_a(Epics::Error::TechnicalError)
      end
    end

    describe 'the failed request' do
      # HTD, the uploads and HVE send the bank key digests; the fixture holds bank keys for host SIZBN001 only.
      let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
      let(:upload) { Epics::CCT.new(client, 'pain.001 document').tap { |order| order.transaction_id = 'B5F1A3D2C4E6F8091A2B3C4D5E6F7A8B' } }

      before { stubs.post('/') { [503, { 'Content-Type' => 'text/html' }, maintenance_page] } }

      describe 'H003' do
        let(:version) { Epics::Keyring::VERSION_24 }
        let(:download) do
          Epics::STA.new(client, from: Date.new(2014, 9, 1), to: Date.new(2014, 9, 30))
               .tap { |order| order.transaction_id = 'B5F1A3D2C4E6F8091A2B3C4D5E6F7A8B' }
        end

        { 'the initialisation of a download' => [-> { Epics::HTD.new(client).to_xml }, 'Initialisation', 'HTD', true],
          'the initialisation of an upload'  => [-> { upload.to_xml }, 'Initialisation', 'CCT', true],
          'the order data of an upload'      => [-> { upload.to_transfer_xml }, 'Transfer', nil, false],
          'a further segment of a download'  => [-> { download.to_transfer_download_xml(2, true) }, 'Transfer', nil, true],
          'the receipt of a download'        => [-> { download.to_receipt_xml }, 'Receipt', nil, true] }
          .each do |request, (request_xml, phase, order_type, retryable)|
          it "#{retryable ? 'is' : 'is not'} retryable after #{request}" do
            expect { subject.post('/', instance_exec(&request_xml)) }
              .to raise_error(Epics::Error::HTTPError) do |error|
              expect(error.phase).to eq(phase)
              expect(error.order_type).to eq(order_type)
              expect(error.retryable?).to eq(retryable)
            end
          end
        end
      end

      describe 'H004' do
        let(:version) { Epics::Keyring::VERSION_25 }
        let(:download) do
          Epics::STA.new(client, from: Date.new(2014, 9, 1), to: Date.new(2014, 9, 30))
               .tap { |order| order.transaction_id = 'B5F1A3D2C4E6F8091A2B3C4D5E6F7A8B' }
        end
        let(:hve) { Epics::HVE.new(client, order_id: 'N02A', digest: Digest::SHA256.digest('pain.001 in the EDS')) }

        { 'the initialisation of a download' => [-> { Epics::HTD.new(client).to_xml }, 'Initialisation', 'HTD', true],
          'the initialisation of an upload'  => [-> { upload.to_xml }, 'Initialisation', 'CCT', true],
          'the order data of an upload'      => [-> { upload.to_transfer_xml }, 'Transfer', nil, false],
          'a further segment of a download'  => [-> { download.to_transfer_download_xml(2, true) }, 'Transfer', nil, true],
          'the receipt of a download'        => [-> { download.to_receipt_xml }, 'Receipt', nil, true],
          'the initialisation of an HVE'     => [-> { hve.to_xml }, 'Initialisation', 'HVE', false],
          'key management'                   => [-> { Epics::INI.new(client).to_xml }, nil, 'INI', true],
          'HEV'                              => [-> { Epics::HEV.new(client).to_xml }, nil, nil, true] }
          .each do |request, (request_xml, phase, order_type, retryable)|
          it "#{retryable ? 'is' : 'is not'} retryable after #{request}" do
            expect { subject.post('/', instance_exec(&request_xml)) }
              .to raise_error(Epics::Error::HTTPError) do |error|
              expect(error.phase).to eq(phase)
              expect(error.order_type).to eq(order_type)
              expect(error.retryable?).to eq(retryable)
            end
          end
        end
      end

      describe 'H005' do
        let(:version) { Epics::Keyring::VERSION_30 }
        let(:hve) do
          Epics::HVE.new(client, order_id: 'N02A', digest: Digest::SHA256.digest('pain.001 in the EDS'),
                                 service: { service_name: 'SCT', service_option: 'VOI', msg_name: 'pain.001' })
        end
        let(:hvs) do
          Epics::HVS.new(client, order_id: 'N02A', digest: Digest::SHA256.digest('pain.001 in the EDS'),
                                 service: { service_name: 'SCT', service_option: 'VOI', msg_name: 'pain.001' })
        end

        { 'the initialisation of an upload' => [-> { upload.to_xml }, 'Initialisation', 'BTU', true],
          'the order data of an upload'     => [-> { upload.to_transfer_xml }, 'Transfer', nil, false],
          'the initialisation of an HVE'    => [-> { hve.to_xml }, 'Initialisation', 'HVE', false],
          'the initialisation of an HVS'    => [-> { hvs.to_xml }, 'Initialisation', 'HVS', false] }
          .each do |request, (request_xml, phase, order_type, retryable)|
          it "#{retryable ? 'is' : 'is not'} retryable after #{request}" do
            expect { subject.post('/', instance_exec(&request_xml)) }
              .to raise_error(Epics::Error::HTTPError) do |error|
              expect(error.phase).to eq(phase)
              expect(error.order_type).to eq(order_type)
              expect(error.retryable?).to eq(retryable)
            end
          end
        end
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
        expect(error.body_excerpt).to eq('Welcome to the bank portal')
        expect(error).not_to respond_to(:status)
      end
    end

    it 'raises an InvalidResponseError for an empty body' do
      stubs.post('/') { [200, {}, ''] }

      expect { subject.post('/') }.to raise_error(Epics::InvalidResponseError) do |error|
        expect(error.body_excerpt).to eq('')
        expect(error).not_to be_a(Epics::Error::TechnicalError)
      end
    end

    it 'raises an InvalidResponseError for an EBICS document cut off before its ReturnCode' do
      stubs.post('/') { [200, {}, '<ebicsResponse xmlns="urn:org:ebics:H004"><header authenticate="true"><static>'] }

      expect { subject.post('/') }.to raise_error(Epics::InvalidResponseError) do |error|
        expect(error.body_excerpt).to start_with('<ebicsResponse')
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

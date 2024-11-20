# frozen_string_literal: true

RSpec.describe Epics::ParseEbics do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'HOST', 'USER', 'PARTNER') }
  subject do
    Faraday.new do |builder|
      builder.use Epics::ParseEbics, { client: client }
      builder.adapter :test, Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('/business_nok') { [200, {}, File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'ebics_business_nok.xml'))] }
        stub.post('/technical_nok') { [200, {}, File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'ebics_technical_nok.xml'))] }
        stub.post('/ok') { [200, {}, File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'hpb_response_ebics_ns.xml'))] }
        stub.post('/timeout') { raise Faraday::TimeoutError }
        stub.post('/no_connection') { raise Faraday::ConnectionFailed, 'peer has finished all lan parties and gone home' }
      end
    end
  end

  it 'will handle errornous response with raising the related error class' do
    expect { subject.post('/business_nok') }.to raise_error(Epics::Error::BusinessError, 'EBICS_PROCESSING_ERROR - During processing of the EBICS request, other business-related errors have ocurred')
    expect { subject.post('/technical_nok') }.to raise_error(Epics::Error::TechnicalError, 'EBICS_AUTHENTICATION_FAILED - Authentication signature error')
  end

  it 'will parsed as Epics::Response' do
    expect(subject.post('/ok').body).to be_kind_of(Epics::Response)
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

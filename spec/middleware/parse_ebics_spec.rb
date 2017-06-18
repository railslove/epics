RSpec.describe Epics::ParseEbics do

  subject do
    Faraday.new do |builder|
      builder.adapter :test, Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('/business_nok') {[ 200, {}, File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'ebics_business_nok.xml') )  ]}
        stub.post('/technical_nok') {[ 200, {}, File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'ebics_technical_nok.xml') )  ]}
        stub.post('/technical_nok_unkown') {[ 200, {}, "The Server cannot process your request." ]}
        stub.post('/ok') {[ 200, {}, File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'hpb_response_ebics_ns.xml') )  ]}
      end
      builder.use Epics::ParseEbics
    end
  end

  it "will handle errornous response with raising the related error class" do
    expect { subject.post("/business_nok") }.to raise_error(Epics::Error::BusinessError, "EBICS_PROCESSING_ERROR - During processing of the EBICS request, other business-related errors have ocurred")
    expect { subject.post("/technical_nok") }.to raise_error(Epics::Error::TechnicalError, "EBICS_AUTHENTICATION_FAILED - Authentication signature error")
  end

  it "will show errornous response messages with unknown error code" do
    expect { subject.post("/technical_nok_unkown") }.to raise_error(Epics::Error::TechnicalError, "EPICS_UNKNOWN - The Server cannot process your request.")
  end

  it "will parsed as Epics::Response" do
    expect(subject.post("/ok").body).to be_kind_of(Epics::Response)
  end

end

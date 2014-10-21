RSpec.describe Epics::ParseEbics do

  subject do
    Faraday.new do |builder|
      builder.adapter :test, Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('/business_nok') {[ 200, {}, File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'ebics_business_nok.xml') )  ]}
        stub.post('/technical_nok') {[ 200, {}, File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'ebics_technical_nok.xml') )  ]}
      end
      builder.use Epics::ParseEbics
    end
  end

  it "will handle errornous response with raising the related error class" do
    expect { subject.post("/business_nok") }.to raise_error(Epics::Error::BusinessError, "EBICS_PROCESSING_ERROR - During processing of the EBICS request, other business-related errors have ocurred")
    expect { subject.post("/technical_nok") }.to raise_error(Epics::Error::TechnicalError, "EBICS_AUTHENTICATION_FAILED - Authentication signature error")
  end

end

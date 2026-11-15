require 'spec_helper'

describe Epics::Error::BusinessError do

  subject { Epics::Error::BusinessError.new(code) }

  before do
    stub_const("Epics::Error::BusinessError::ERRORS", {
      "123" => {
        "symbol" => "BOTTMUEHLE",
        "short_text" => "home of awesome",
      }
    })
  end

  let(:code) { '123' }

  describe '#to_s' do

    it 'returns a message composed of symbol and short text' do
      expect(subject.to_s).to eql('BOTTMUEHLE - home of awesome')
    end
  end

  describe '#code' do
    it 'returns the code' do
      expect(subject.code).to eql('123')
    end
  end

  describe '#symbol' do
    it 'returns the symbol' do
      expect(subject.symbol).to eql('BOTTMUEHLE')
    end
  end

  describe '#short_text' do
    it 'returns the short text' do
      expect(subject.short_text).to eql('home of awesome')
    end
  end

end

describe Epics::Error::HTTPError do
  it 'truncates a long body' do
    error = described_class.new(500, 'x' * 1000)

    expect(error.body.length).to eq(Epics::Error::BODY_EXCERPT_LENGTH)
  end

  it 'falls back to the bare status for an unknown reason phrase' do
    expect(described_class.new(599, '').message).to eq('HTTP 599')
  end

  it 'names the HTTP status in symbol and short text instead of EPICS_UNKNOWN' do
    error = described_class.new(503, '')

    expect(error.symbol).to eq('HTTP_503')
    expect(error.short_text).to eq('Service Unavailable')
    expect(error.code).to be_nil
  end

  it 'keeps the HTTP status in the symbol for an unknown reason phrase' do
    error = described_class.new(599, '')

    expect(error.symbol).to eq('HTTP_599')
    expect(error.short_text).to eq('unknown')
  end
end

describe Epics::InvalidResponseError do
  it 'can be rescued as an Epics::Error but not as a TechnicalError' do
    error = described_class.new('ReturnCode')

    expect(error).to be_a(Epics::Error)
    expect(error).not_to be_a(Epics::Error::TechnicalError)
  end

  it 'names the missing field in message, symbol and short text' do
    error = described_class.new('ReturnCode')

    expect(error.message).to eq("Could not read ReturnCode from the bank's response")
    expect(error.symbol).to eq('EPICS_INVALID_RESPONSE')
    expect(error.short_text).to eq(error.message)
    expect(error.code).to be_nil
    expect(error.field).to eq('ReturnCode')
  end

  it 'appends the message of the original error' do
    error = described_class.new('NumSegments', ArgumentError.new('invalid value for Integer(): ""'))

    expect(error.message).to eq(%q{Could not read NumSegments from the bank's response (invalid value for Integer(): "")})
  end

  it 'truncates a long body and keeps it nil when none is given' do
    expect(described_class.new('ReturnCode', body: 'x' * 1000).body.length).to eq(Epics::Error::BODY_EXCERPT_LENGTH)
    expect(described_class.new('NumSegments').body).to be_nil
  end
end

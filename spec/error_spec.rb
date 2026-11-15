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

RSpec.describe Epics::Error::HTTPError do
  it 'can be rescued as an Epics::Error but not as a TechnicalError' do
    error = described_class.new(503, '')

    expect(error).to be_a(Epics::Error)
    expect(error).not_to be_a(Epics::Error::TechnicalError)
  end

  describe '#message' do
    it 'names the status and its standard reason phrase' do
      expect(described_class.new(503, '').message).to eq('HTTP 503 Service Unavailable')
    end

    it 'names only the status when it has no standard reason phrase' do
      expect(described_class.new(599, '').message).to eq('HTTP 599')
    end
  end

  describe '#symbol' do
    it 'is HTTP_ followed by the status' do
      expect(described_class.new(503, '').symbol).to eq('HTTP_503')
    end
  end

  describe '#short_text' do
    it 'is the reason phrase' do
      expect(described_class.new(503, '').short_text).to eq('Service Unavailable')
    end

    it 'is unknown when the status has no standard reason phrase' do
      expect(described_class.new(599, '').short_text).to eq('unknown')
    end
  end

  describe '#code' do
    it 'is nil, as there is no EBICS return code' do
      expect(described_class.new(503, '').code).to be_nil
    end
  end

  describe '#body' do
    it 'keeps the first 500 characters of a long body' do
      expect(described_class.new(503, 'x' * 1000).body).to eq('x' * 500)
    end

    it 'is empty without a body' do
      expect(described_class.new(503, nil).body).to eq('')
    end
  end
end

RSpec.describe Epics::InvalidResponseError do
  it 'can be rescued as an Epics::Error but not as a TechnicalError' do
    error = described_class.new('ReturnCode')

    expect(error).to be_a(Epics::Error)
    expect(error).not_to be_a(Epics::Error::TechnicalError)
  end

  describe '#message' do
    it 'names the missing field' do
      expect(described_class.new('ReturnCode').message).to eq("Could not read ReturnCode from the bank's response")
    end

    it 'appends the message of the original error' do
      original = ArgumentError.new('invalid value for Integer(): ""')

      expect(described_class.new('NumSegments', original).message)
        .to eq(%q{Could not read NumSegments from the bank's response (invalid value for Integer(): "")})
    end

    it 'names the field when raised with a message, as for a missing DataDigest' do
      expect { raise described_class, 'DataDigest' }
        .to raise_error(Epics::Error, "Could not read DataDigest from the bank's response") do |error|
        expect(error.field).to eq('DataDigest')
      end
    end
  end

  describe '#symbol' do
    it 'is EPICS_INVALID_RESPONSE' do
      expect(described_class.new('ReturnCode').symbol).to eq('EPICS_INVALID_RESPONSE')
    end
  end

  describe '#short_text' do
    it 'is the message' do
      expect(described_class.new('ReturnCode').short_text).to eq("Could not read ReturnCode from the bank's response")
    end
  end

  describe '#code' do
    it 'is nil, as there is no EBICS return code' do
      expect(described_class.new('ReturnCode').code).to be_nil
    end
  end

  describe '#field' do
    it 'is the field that could not be read' do
      expect(described_class.new('ReturnCode').field).to eq('ReturnCode')
    end
  end

  describe '#body' do
    it 'is nil without a body' do
      expect(described_class.new('ReturnCode').body).to be_nil
    end

    it 'keeps the first 500 characters of a long body' do
      expect(described_class.new('ReturnCode', body: 'x' * 1000).body).to eq('x' * 500)
    end
  end
end

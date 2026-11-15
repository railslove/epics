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

    it 'uses the reason phrase the server sent' do
      expect(described_class.new(503, '', reason_phrase: 'Wartungsarbeiten').message).to eq('HTTP 503 Wartungsarbeiten')
    end

    it 'falls back to the standard reason phrase when the server sent an empty one' do
      expect(described_class.new(503, '', reason_phrase: '').message).to eq('HTTP 503 Service Unavailable')
    end

    it 'strips whitespace around the reason phrase the server sent' do
      expect(described_class.new(503, '', reason_phrase: ' Wartungsarbeiten ').message).to eq('HTTP 503 Wartungsarbeiten')
    end

    it 'names a redirect, the usual sign of a wrong bank URL' do
      expect(described_class.new(302, '').message).to eq('HTTP 302 Found')
    end

    it 'names a captive portal that answers with 511' do
      expect(described_class.new(511, '').message).to eq('HTTP 511 Network Authentication Required')
    end

    it 'names only the status when it has no standard reason phrase' do
      expect(described_class.new(599, '').message).to eq('HTTP 599')
    end

    it 'is UTF-8 when Net::HTTP hands over a non-ASCII reason phrase as binary, so it can be logged as JSON' do
      message = described_class.new(503, '', reason_phrase: 'Störung'.b).message

      expect(message).to eq('HTTP 503 Störung')
      expect(message.to_json).to eq('"HTTP 503 Störung"')
    end
  end

  describe '#reason_phrase' do
    it 'is the standard reason phrase when the server sent none' do
      expect(described_class.new(503, '').reason_phrase).to eq('Service Unavailable')
    end

    it 'is the reason phrase the server sent' do
      expect(described_class.new(503, '', reason_phrase: 'Wartungsarbeiten').reason_phrase).to eq('Wartungsarbeiten')
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

    it 'names the status when it has no standard reason phrase' do
      expect(described_class.new(599, '').short_text).to eq('HTTP 599')
    end
  end

  describe '#code' do
    it 'is nil, as there is no EBICS return code' do
      expect(described_class.new(503, '').code).to be_nil
    end
  end

  describe '#body_excerpt' do
    it 'keeps the first 500 characters of a long body' do
      expect(described_class.new(503, 'x' * 1000).body_excerpt).to eq('x' * 500)
    end

    it 'counts characters, not bytes' do
      expect(described_class.new(503, 'ä' * 1000).body_excerpt).to eq('ä' * 500)
    end

    it 'reads a body without a charset as UTF-8, so it can be logged as JSON' do
      excerpt = described_class.new(503, ('ä' * 600).b).body_excerpt

      expect(excerpt).to eq('ä' * 500)
      expect(excerpt.to_json).to eq(%("#{'ä' * 500}"))
    end

    it 'converts a body the server declared as ISO-8859-1 to UTF-8' do
      body = "<p>Wartungsarbeiten f\xFCr das Banking</p>".dup.force_encoding(Encoding::ISO_8859_1)

      expect(described_class.new(503, body).body_excerpt).to eq('<p>Wartungsarbeiten für das Banking</p>')
    end

    it 'replaces bytes that are not valid UTF-8' do
      body = "<p>Wartungsarbeiten f\xFCr das Banking</p>".b

      expect(described_class.new(503, body).body_excerpt).to eq("<p>Wartungsarbeiten f\uFFFDr das Banking</p>")
    end

    it 'is empty without a body' do
      expect(described_class.new(503, nil).body_excerpt).to eq('')
    end
  end

  describe '#retryable?' do
    { 'the initialisation of an upload'  => [{ phase: 'Initialisation', order_type: 'BTU' }, true],
      'the order data of an upload'      => [{ phase: 'Transfer', order_data_sent: true }, false],
      'a further segment of a download'  => [{ phase: 'Transfer', order_data_sent: false }, true],
      'order data without a phase'       => [{ order_data_sent: true }, false],
      'the initialisation of an HVE'     => [{ phase: 'Initialisation', order_type: 'HVE' }, false],
      'the initialisation of an HVS'     => [{ phase: 'Initialisation', order_type: 'HVS' }, false],
      'a request without a phase'        => [{}, true] }
      .each do |request, (request_options, retryable)|
      it "is #{retryable} after #{request}" do
        expect(described_class.new(503, '', request_read: true, **request_options).retryable?).to eq(retryable)
      end
    end

    it 'is false when the request could not be read' do
      expect(described_class.new(503, '', phase: 'Initialisation', order_type: 'HTD').retryable?).to be(false)
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

  describe '#body_excerpt' do
    it 'is nil without a body' do
      expect(described_class.new('ReturnCode').body_excerpt).to be_nil
    end

    it 'keeps the first 500 characters of a long body' do
      expect(described_class.new('ReturnCode', body: 'x' * 1000).body_excerpt).to eq('x' * 500)
    end

    it 'reads a body without a charset as UTF-8, so it can be logged as JSON' do
      body = '<p>Willkommen im Online-Banking für Geschäftskunden</p>'.b
      excerpt = described_class.new('ReturnCode', body: body).body_excerpt

      expect(excerpt).to eq('<p>Willkommen im Online-Banking für Geschäftskunden</p>')
      expect(excerpt.to_json).to eq('"<p>Willkommen im Online-Banking für Geschäftskunden</p>"')
    end
  end
end

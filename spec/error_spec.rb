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

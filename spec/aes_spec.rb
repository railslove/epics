RSpec.describe Epics::Crypt::Aes do
  subject { described_class.new.tap { |aes| aes.key = Base64.decode64('5fXINXF7C+gRpK+q1Y12lw==') } }
  let(:pad) {
    ->(text) {
      cipher = subject.instance_eval { use_cipher(:encrypt) }
      subject.instance_eval { pad(cipher, text) }
    }
  }
  let(:unpad) {
    ->(text) {
      subject.instance_eval { unpad(text) }
    }
  }

  describe '#encrypt' do
    it 'valid' do
      expect(Base64.strict_encode64(subject.encrypt('a' * 13))).to eq('f8kId9dqBLaEbhSz9PBv7g==')
    end
  end

  describe '#decrypt' do
    it 'valid' do
      expect(subject.decrypt(subject.encrypt('a' * 13))).to eq('a' * 13)
    end
  end

  describe '#pad' do
    it 'will complete the block to the next 16byte' do
      expect(pad.("\x01" * 13).size).to eq(16)
    end

    it 'will pad a complete block if the size is a multiple of 16' do
      expect(pad.("\x01" * 16).size).to eq(32)
    end

    it 'will set the last byte to the padding length' do
      expect(pad.("\x01" * 13)[-1]).to eq([3].pack('C*'))
    end
  end

  describe '#unpad' do
    it 'valid' do
      expect(unpad.(pad.('a' * 13))).to eq('a' * 13)
    end
  end
end

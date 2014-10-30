RSpec.describe Epics::GenericUploadRequest do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  subject { described_class.new(client, "\x01" * 12) }

  describe '#pad' do

    it 'will complete the block to the next 16byte' do
      expect(subject.pad("\x01" * 13).size).to eq(16)
    end

    it 'will pad a complete block if the size is a multiple of 16' do
      expect(subject.pad("\x01" * 16).size).to eq(32)
    end

    it 'will set the last byte to the padding length' do
      expect(subject.pad("\x01" * 13)[-1]).to eq([3].pack("C*"))
    end
  end
end
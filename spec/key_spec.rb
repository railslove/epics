RSpec.describe Epics::Key do

  subject { described_class.new( File.read(File.join( File.dirname(__FILE__), 'fixtures', 'e002.pem'))) }

  describe '#public_digest' do

    it 'foo' do
      expect(subject.public_digest).to eq("rwIxSUJAVEFDQ0sdYe+CybdspMllDG6ArNtdCzUbT1E=")
    end
  end

end

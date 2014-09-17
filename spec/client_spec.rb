RSpec.describe Epics::Client do

  subject { described_class.new( File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key'), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  describe '#keys' do
    it 'holds all keys, user and bank' do
      expect(subject.keys).to match(a_hash_including(
        "E002" => be_kind_of(Epics::Key),
        "X002" => be_a(Epics::Key),
        "A006" => be_a(Epics::Key),
        "SIZBN001.E002" => be_a(Epics::Key),
        "SIZBN001.X002" => be_a(Epics::Key)
      ))
    end
  end

  describe '#e' do
    it 'the encryption key' do
      expect(subject.e.public_digest).to eq("rwIxSUJAVEFDQ0sdYe+CybdspMllDG6ArNtdCzUbT1E=")
    end
  end

  describe '#x' do
    it 'the signing key' do
      expect(subject.x.public_digest).to eq("Jjcu97qg595PPn+0OvqBOBIskMIiStNYYXyjgWHeBhE=")
    end
  end

  describe '#a' do
    it 'the authentication key' do
      expect(subject.a.public_digest).to eq("9ay3tc+I3MgJBaroeD7XJfOtHcq7IR23fljWefl0dzk=")
    end
  end

  describe '#bank_e' do
    it 'the banks encryption key' do
      expect(subject.bank_e.public_digest).to eq("dFAYe281vj9NB7w+VoWIdfHnjY9hNbZLbHsDOu76QAE=")
    end
  end
  describe '#bank_x' do
    it 'the banks signing key' do
      expect(subject.bank_x.public_digest).to eq("dFAYe281vj9NB7w+VoWIdfHnjY9hNbZLbHsDOu76QAE=")
    end
  end
end

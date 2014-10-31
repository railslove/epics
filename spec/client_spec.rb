RSpec.describe Epics::Client do

  subject { described_class.new( File.read(File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  describe 'attributes' do
    it { expect(subject.host_id).to eq('SIZBN001') }
    it { expect(subject.keys_content).to match(/SIZBN001.E002/) }
    it { expect(subject.passphrase).to eq('secret') }
    it { expect(subject.partner_id).to eq('EBICS') }
    it { expect(subject.url).to eq('https://194.180.18.30/ebicsweb/ebicsweb') }
    it { expect(subject.user_id).to eq('EBIX') }

    it 'holds all keys, user and bank' do
      expect(subject.keys).to match(a_hash_including(
        "E002" => be_a(Epics::Key),
        "X002" => be_a(Epics::Key),
        "A006" => be_a(Epics::Key),
        "SIZBN001.E002" => be_a(Epics::Key),
        "SIZBN001.X002" => be_a(Epics::Key)
      ))
    end

  end

  describe '#inspect' do
    it 'will not print the complete object' do
      expect(subject.inspect).to include("@keys=#{subject.keys.keys}")
      expect(subject.inspect).to include("@user_id=\"#{subject.user_id}\"")
      expect(subject.inspect).to include("@partner_id=\"#{subject.partner_id}\"")
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

  describe '#HPB' do
    before do
      stub_request(:post, "https://194.180.18.30/ebicsweb/ebicsweb")
        .with(:body => %r[<?xml(.*)ebicsNoPubKeyDigestsRequest>])
        .to_return(status: 200, body: File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml', 'hpb_response.xml')))
    end

    it { expect(subject.HPB).to match([be_a(Epics::Key), be_a(Epics::Key)]) }

    it 'changes the SIZBN001.(E|X)002 keys' do
      expect { subject.HPB }.to change { subject.keys["SIZBN001.E002"] }
      expect { subject.HPB }.to change { subject.keys["SIZBN001.X002"] }
    end

    describe 'crypto' do
      let(:e_key) do
        Epics::Key.new(OpenSSL::PKey::RSA.new(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'bank_e.pem'))))
      end

      before { subject.HPB }

      it { expect(subject.keys["SIZBN001.E002"].public_digest).to eq(e_key.public_digest) }
      it { expect(subject.keys["SIZBN001.X002"].public_digest).to eq(e_key.public_digest) }
    end
  end

  describe '#HTD' do
    before do
      allow(subject).to receive(:download).and_return( File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml', 'htd_order_data.xml')))
    end

    it 'sets @iban' do
      expect { subject.HTD }.to change { subject.instance_variable_get("@iban") }
    end

    it 'sets @bic' do
      expect { subject.HTD }.to change { subject.instance_variable_get("@bic") }
    end

    it 'sets @name' do
      expect { subject.HTD }.to change { subject.instance_variable_get("@name") }
    end
  end
end

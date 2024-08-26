RSpec.describe Epics::SignatureAlgorithm::RsaPss do

  subject { described_class.new( File.read(File.join( File.dirname(__FILE__), 'fixtures', 'e002.pem'))) }

  describe '#public_digest' do

    it 'will calculate the digest as the specification suggests' do
      expect(subject.public_digest).to eq("rwIxSUJAVEFDQ0sdYe+CybdspMllDG6ArNtdCzUbT1E=")
    end
  end


  describe '#sign' do
    let(:dsi) { OpenSSL::Digest::SHA256.new.digest("ruby is great") }

    it 'will generated a digest that can be verified with openssl key.verify_pss' do
      signed_digest = Base64.encode64(subject.sign(dsi)).strip
      verification_result = subject.verify(signed_digest, dsi)

      expect(verification_result).to eq(true)
    end

  end


end

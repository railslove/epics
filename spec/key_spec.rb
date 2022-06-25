RSpec.describe Epics::Key do

  subject { described_class.new( File.read(File.join( File.dirname(__FILE__), 'fixtures', 'e002.pem'))) }

  describe '#public_digest' do

    it 'will calculate the digest as the specification suggests' do
      expect(subject.public_digest).to eq("rwIxSUJAVEFDQ0sdYe+CybdspMllDG6ArNtdCzUbT1E=")
    end
  end


  describe '#sign' do
    let(:dsi) { OpenSSL::Digest::SHA256.new.digest("ruby is great") }

    it 'will generated a digest that can be verified with openssl key.verify_pss' do
      signed_digest = subject.sign(dsi)

      key = subject.key

      verification_result = key.verify_pss(
                              'SHA256',
                              Base64.decode64(signed_digest),
                              dsi,
                              salt_length: :digest,
                              mgf1_hash:   'SHA256',
                            )

      expect(verification_result).to eq(true)
    end

  end


end

RSpec.describe Epics::Key do

  subject { described_class.new( File.read(File.join( File.dirname(__FILE__), 'fixtures', 'e002.pem'))) }

  describe '#public_digest' do

    it 'will calculate the digest as the specification suggests' do
      expect(subject.public_digest).to eq("rwIxSUJAVEFDQ0sdYe+CybdspMllDG6ArNtdCzUbT1E=")
    end
  end


  describe '#sign' do
    # echo QwpW2a/Cu43TmibTIABrLuyZsiWY9oL8fARob0YoytU= | base64 -d | openssl dgst -sha256 -sign spec/fixtures/e002.pem -sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:32 | base64 -w0
    let(:openssl) { "bZyyz4vPqRTyU7hfJ1cv6FgihhQOi8NTbk8nSuPEoXeuODJOQkCvxRDw1QoUGa181EbaPACYwJbQ9uwgwgb/b3k+bQ4KdJzCjbCrh7rKmQvLmnLgfQWIxp5hZdw7ebaR36rlpoHQ8yzlm0hhVLCDu2+HMIu5SA4kEd4ci9ZfVRm+aDVOwQZNLXNyKWAW/ZYkbsH+TzX4euIh831JBxGq967U5DVz6Aa8qqJPUafYiSE4H8x36Nw3qW0ib2DDcvGFTqtA6MeJyI1Quzko5+kSdnZkpIeZr/SXB1WnocYWR1oYoVG4+P+cMyCNiYSV4/NVEL4jmUbfdCSmUYo5cfPlJg==" }

    # r = subject.recover(sig)
    # masked_db = r[0..222]
    # hm = r[223..-2]
    # db_mask = MGF1.new.generate(hm, masked_db.size)
    # db = MGF1.new.xor(masked_db, db_mask)
    # salt = db[-32..-1]
    # Base64.encode64(salt)
    let(:salt) { "HkCke9oBSGTo2J20Xq8LZ/ouRHfB/ySlXf4+Cr45RV0=" }

    let(:dsi) { OpenSSL::Digest::SHA256.new.digest("ruby is great") }

    it 'will be compliant with openssl' do
      expect( subject.sign( dsi, Base64.decode64(salt)) ).to eq(openssl)
    end

  end


end

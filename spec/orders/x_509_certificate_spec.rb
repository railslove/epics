RSpec.describe Epics::X509Certificate do
  subject(:x_509_certificate) { described_class.new(crt_content) }

  let(:key) { OpenSSL::PKey::RSA.new(2048) }
  let(:crt_content) { generate_x_509_crt(key, distinguished_name) }
  let(:distinguished_name) { '/C=GB/O=TestOrg/CN=test.example.org' }

  describe '#issuer' do
    it 'returns the issuer of the certificate' do
      expect(x_509_certificate.issuer.to_s).to eq(distinguished_name)
    end
  end
  
  describe '#version' do
    it 'returns the version of the certificate' do
      expect(x_509_certificate.version).to eq(2)
    end
  end
  
  describe '#data' do
    it 'returns the base64 encoded certificate data' do
      expect(x_509_certificate.data).to start_with('MIIDDzCCAfegAwIBAgIBATANBgkqhkiG9w0BA')
      expect(x_509_certificate.data).to end_with('==')
    end
  end
end

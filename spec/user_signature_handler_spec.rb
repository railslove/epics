RSpec.describe Epics::Handlers::UserSignatureHandler do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:document) { "\x01" * 12 }
  let(:cct) { Epics::CCT.new(client, document) }

  before { allow_any_instance_of(OpenSSL::Cipher::AES).to receive(:random_key).and_return(Base64.strict_decode64('NoG3dD6eHqtYTYrJn6TIzA==')) }

  let(:crypt_service) { cct.instance_variable_get(:@crypt_service) }
  let(:digest) { crypt_service.hash(document) }
  subject { Nokogiri::XML(cct.to_xml) }
  let(:signature_data_encrypted_node) { subject.xpath("//ebics:SignatureData", ebics: 'urn:org:ebics:H004').first }
  let(:signature_data_node) { Nokogiri::XML(Zlib::Inflate.inflate(crypt_service.decrypt_by_key(cct.transaction_key, Base64.strict_decode64(signature_data_encrypted_node.content)))) }
  let(:signature_value_node) { signature_data_node.xpath("//ebics:SignatureValue", ebics: 'http://www.ebics.org/S001').first }

  describe '#signature_value' do

    # it 'will be the signed document' do
    #   expect(signature_value_node.content).to eq('cD3DF2ytthmdj/7m53JWZK6IOo26nmaGP4LHdwUqMh3zRTlc7EiidC8oxKqVIFWC3dq7/EaZvKUFrAEc/h64IwlBFyFHOBUW9Xfl...I5KXr1dmWD1mhWYotpdIFXzORS1Bd14C2zh0vpDBhSz7rWu1uNaFy2CxfjEg0tyeapMKsaO8P9MX0SL6dEWE2cOL12hVJu+0Q==')
    # end

    it 'can be verified with the same key' do
      expect(client.keyring.user_signature.key.verify(signature_value_node.content, digest)).to eq(true)
    end
  end
end

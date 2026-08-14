RSpec.describe 'key file decryption' do
  let(:client) do
    Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')),
                      'secret', 'https://example.com/ebics', 'SIZBN001', 'EBIX', 'EBICS')
  end

  it 'round-trips a PEM' do
    pem = client.keyring.user_signature.key.key.to_pem

    expect(client.send(:decrypt, client.send(:encrypt, pem))).to eq(pem)
  end

  # The padding check catches a wrong passphrase 255 times out of 256. This is the
  # remaining case: correctly padded plaintext that is not a key.
  it 'rejects correctly padded plaintext that is not a PEM' do
    expect { client.send(:decrypt, client.send(:encrypt, 'not a pem at all')) }
      .to raise_error(OpenSSL::Cipher::CipherError, /wrong passphrase/)
  end

  it 'fails the same way whichever branch trips' do
    json = client.send(:dump_keys)

    expect do
      Epics::Client.new(json, 'wrong_passphrase', 'https://example.com/ebics', 'SIZBN001', 'EBIX', 'EBICS')
    end.to raise_error(OpenSSL::Cipher::CipherError)
  end
end

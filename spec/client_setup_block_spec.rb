RSpec.describe 'Epics::Client.setup with a block' do
  # Keys are generated after #initialize returns, so the block cannot be forwarded to
  # .new -- it would see an empty keyring.
  it 'yields a client whose keys exist' do
    yielded = nil
    Epics::Client.setup('secret', 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01', 1024) do |client|
      yielded = { signature: client.signature_key, authentication: client.authentication_key,
                  encryption: client.encryption_key }
    end

    expect(yielded.values).to all(be_a(Epics::SignatureAlgorithm::Base))
  end

  it 'yields the client that is returned' do
    yielded = nil
    returned = Epics::Client.setup('secret', 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01', 1024) do |c|
      yielded = c
    end

    expect(yielded).to be(returned)
  end

  it 'can render the initialisation letter from inside the block' do
    expect do
      Epics::Client.setup('secret', 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01', 1024,
                          version: Epics::Keyring::VERSION_30) do |client|
        client.ini_letter('Test Bank')
      end
    end.not_to raise_error
  end

  it 'yields after certificates have been generated on H005' do
    yielded = nil
    Epics::Client.setup('secret', 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01', 1024,
                        version: Epics::Keyring::VERSION_30) do |client|
      yielded = client.keyring.user_signature.certificate
    end

    expect(yielded).to be_a(Epics::Crypt::X509)
  end
end

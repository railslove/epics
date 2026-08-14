RSpec.describe 'key file preservation' do
  let(:keyfile) { File.read(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')) }
  let(:url) { 'https://example.com/ebics' }

  def load_client(host_id)
    Epics::Client.new(keyfile, 'secret', url, host_id, 'EBIX', 'EBICS')
  end

  def entries(client)
    JSON.parse(client.send(:dump_keys))
  end

  context 'when host_id matches the stored bank keys' do
    subject(:reloaded) { load_client('SIZBN001') }

    it 'loads the bank keys into the keyring' do
      expect(reloaded.bank_authentication_key).not_to be_nil
      expect(reloaded.bank_encryption_key).not_to be_nil
    end

    it 'writes every entry back' do
      expect(entries(reloaded).keys).to match_array(JSON.parse(keyfile).keys)
    end
  end

  # A renamed host, a reused key file or a case difference leaves the bank entries
  # unrecognised. They must survive the round-trip regardless.
  context 'when host_id does not match the stored bank keys' do
    subject(:reloaded) { load_client('OTHERHOST') }

    it 'cannot place the bank keys' do
      expect(reloaded.bank_authentication_key).to be_nil
    end

    it 'still writes every entry back' do
      expect(entries(reloaded).keys).to match_array(JSON.parse(keyfile).keys)
    end

    it 'leaves the unplaced entries untouched' do
      original = JSON.parse(keyfile)
      written = entries(reloaded)

      %w[SIZBN001.E002 SIZBN001.X002].each do |name|
        expect(written[name]).to eq(original[name])
      end
    end

    it 'warns rather than dropping them silently' do
      expect { load_client('OTHERHOST') }
        .to output(/keeping "SIZBN001.E002" in the key file unchanged/).to_stderr
    end
  end

  # A key written by an older EBICS version, still decryptable but of a version this
  # gem no longer builds signatures for.
  context 'with an entry of an unknown signature version' do
    let(:original) { JSON.parse(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key'))) }
    let(:keyfile) { JSON.pretty_generate(original.merge('A004' => original['A006'])) }

    it 'keeps it' do
      reloaded = nil
      expect { reloaded = load_client('SIZBN001') }.to output(/A004/).to_stderr
      expect(entries(reloaded)['A004']).to eq(original['A006'])
    end

    it 'still loads the keys it does understand' do
      reloaded = nil
      expect { reloaded = load_client('SIZBN001') }.to output(/A004/).to_stderr
      expect(reloaded.signature_key).not_to be_nil
    end
  end

  # A wrong passphrase must still fail loudly rather than being kept as unmapped.
  it 'raises on an undecryptable key file' do
    expect { Epics::Client.new(keyfile, 'wrong', url, 'SIZBN001', 'EBIX', 'EBICS') }
      .to raise_error(OpenSSL::Cipher::CipherError)
  end
end

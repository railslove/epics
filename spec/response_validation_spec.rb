RSpec.describe 'Epics::Response validity checks without keys' do
  let(:client) { Epics::Client.new(nil, 'secret', 'https://example.com/ebics', 'HOST01', 'USER01', 'PARTNER01') }
  let(:xml) { File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml', 'upload_init_response.xml')) }

  subject(:response) { Epics::Response.new(client, xml) }

  # A response can arrive before HPB has run, so these must say what is missing rather
  # than fail on nil.
  it 'reports the missing bank key when verifying a signature' do
    expect { response.signature_valid? }
      .to raise_error(Epics::MissingKeyError, /bank's authentication key/)
  end

  it 'reports the missing encryption key when comparing the public digest' do
    expect { response.public_digest_valid? }
      .to raise_error(Epics::MissingKeyError, /encryption key/)
  end

  # The digest is a plain SHA-256 over the authenticated nodes and needs no key at all.
  it 'checks the digest without any key loaded' do
    expect { response.digest_valid? }.not_to raise_error
  end
end

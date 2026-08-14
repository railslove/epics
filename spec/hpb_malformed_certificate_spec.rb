RSpec.describe 'HPB with an unreadable certificate' do
  let(:client) do
    Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')),
                      'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS',
                      version: Epics::Keyring::VERSION_30)
  end

  let(:order_data) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <HPBResponseOrderData xmlns="urn:org:ebics:H005" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <AuthenticationPubKeyInfo>
          <ds:X509Data><ds:X509Certificate>bm90LWEtY2VydGlmaWNhdGU=</ds:X509Certificate></ds:X509Data>
          <AuthenticationVersion>X002</AuthenticationVersion>
        </AuthenticationPubKeyInfo>
        <HostID>SIZBN001</HostID>
      </HPBResponseOrderData>
    XML
  end

  before { allow(client).to receive(:download).and_return(order_data) }

  # A keyring built from a partly unreadable HPB response is not usable, and a warning
  # on stderr is easy to miss on a server.
  it 'fails rather than storing an incomplete keyring' do
    expect { client.HPB }.to raise_error(Epics::InvalidCertificateError)
  end

  it 'says where the certificate came from' do
    expect { client.HPB }.to raise_error(/from the HPB response/)
  end

  it 'includes the underlying OpenSSL error' do
    expect { client.HPB }.to raise_error(/PEM_read_bio_X509/)
  end
end

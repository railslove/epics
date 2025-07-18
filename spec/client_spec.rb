RSpec.describe Epics::Client do
  subject { described_class.new(key, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:key) { File.read(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')) }

  describe 'attributes' do
    it { expect(subject.host_id).to eq('SIZBN001') }
    it { expect(subject.keys_content).to match(/SIZBN001.E002/) }
    it { expect(subject.passphrase).to eq('secret') }
    it { expect(subject.partner_id).to eq('EBICS') }
    it { expect(subject.url).to eq('https://194.180.18.30/ebicsweb/ebicsweb') }
    it { expect(subject.user_id).to eq('EBIX') }

    it 'holds all keys, user and bank' do
      expect(subject.keys).to match(a_hash_including(
                                      'E002' => be_a(Epics::Key),
                                      'X002' => be_a(Epics::Key),
                                      'A006' => be_a(Epics::Key),
                                      'SIZBN001.E002' => be_a(Epics::Key),
                                      'SIZBN001.X002' => be_a(Epics::Key)
                                    ))
    end

    it 'assigns x_509_certificates_content' do
      subject.x_509_certificates_content = { a: 'cert_a', x: 'cert_x', e: 'cert_e' }
      expect(subject.x_509_certificates_content).to eq({ a: 'cert_a', x: 'cert_x', e: 'cert_e' })
    end
  end

  context 'environment settings' do
    before(:each) do
      ENV.delete('EPICS_VERIFY_SSL')
    end

    describe '#verify_ssl?' do
      it 'verifies ssl by default' do
        expect(subject.send(:verify_ssl?)).to eq true
      end

      it 'verifies ssl if there\'s something strange set to your env' do
        ENV['EPICS_VERIFY_SSL'] = 'somethingstrange'
        expect(subject.send(:verify_ssl?)).to eq true
      end

      it 'skips ssl verification if you want to' do
        ENV['EPICS_VERIFY_SSL'] = 'false'
        expect(subject.send(:verify_ssl?)).to eq false
      end
    end
  end

  describe '#inspect' do
    it 'will not print the complete object' do
      expect(subject.inspect).to include("@keys=#{subject.keys.keys}")
      expect(subject.inspect).to include("@user_id=\"#{subject.user_id}\"")
      expect(subject.inspect).to include("@partner_id=\"#{subject.partner_id}\"")
    end
  end

  describe '#e' do
    it 'the encryption key' do
      expect(subject.e.public_digest).to eq('rwIxSUJAVEFDQ0sdYe+CybdspMllDG6ArNtdCzUbT1E=')
    end
  end

  describe '#x' do
    it 'the signing key' do
      expect(subject.x.public_digest).to eq('Jjcu97qg595PPn+0OvqBOBIskMIiStNYYXyjgWHeBhE=')
    end
  end

  describe '#a' do
    it 'the authentication key' do
      expect(subject.a.public_digest).to eq('9ay3tc+I3MgJBaroeD7XJfOtHcq7IR23fljWefl0dzk=')
    end
  end

  describe '#bank_e' do
    it 'the banks encryption key' do
      expect(subject.bank_e.public_digest).to eq('dFAYe281vj9NB7w+VoWIdfHnjY9hNbZLbHsDOu76QAE=')
    end
  end

  describe '#bank_x' do
    it 'the banks signing key' do
      expect(subject.bank_x.public_digest).to eq('dFAYe281vj9NB7w+VoWIdfHnjY9hNbZLbHsDOu76QAE=')
    end
  end

  describe '#order_types' do
    before do
      allow(subject).to receive(:download).and_return(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml',
                                                                          'htd_order_data.xml')))
    end

    it 'extracts the accessible order types of a subscriber' do
      expect(subject.order_types).to match_array(%w[PTK HPD HTD STA HVD HPB HAA HVT HVU HVZ INI SPR PUB HIA HCA HSA HVE
                                                    HVS CCS CCT CIP CD1 CDB CDD])
    end
  end

  describe '#HPB' do
    let(:e_key) do
      Epics::Key.new(OpenSSL::PKey::RSA.new(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'bank_e.pem'))))
    end

    before do
      stub_request(:post, 'https://194.180.18.30/ebicsweb/ebicsweb')
        .with(body: /ebicsNoPubKeyDigestsRequest/)
        .to_return(status: 200, body: File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml',
                                                          'hpb_response_ebics_ns.xml')))
    end

    it { expect(subject.HPB).to match([be_a(Epics::Key), be_a(Epics::Key)]) }

    it 'changes the SIZBN001.(E|X)002 keys' do
      expect { subject.HPB }.to(change { subject.keys['SIZBN001.E002'] })
      expect { subject.HPB }.to(change { subject.keys['SIZBN001.X002'] })
    end

    describe 'crypto' do
      before { subject.HPB }

      it { expect(subject.keys['SIZBN001.E002'].public_digest).to eq(e_key.public_digest) }
      it { expect(subject.keys['SIZBN001.X002'].public_digest).to eq(e_key.public_digest) }
    end

    describe 'when order data wont include namesspaces' do
      before do
        allow(subject).to receive(:download).with(Epics::HPB).and_return(File.read(File.join(File.dirname(__FILE__),
                                                                                             'fixtures', 'xml', 'hpb_response_order_without_ns.xml')))

        subject.HPB
      end

      it { expect(subject.keys['SIZBN001.E002'].public_digest).to eq(e_key.public_digest) }
      it { expect(subject.keys['SIZBN001.X002'].public_digest).to eq(e_key.public_digest) }
    end
  end

  describe '#CDB' do
    let(:cdb_document) { File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml', 'cdb.xml')) }
    before do
      stub_request(:post, 'https://194.180.18.30/ebicsweb/ebicsweb')
        .with(body: %r{<TransactionPhase>Initialisation</TransactionPhase>})
        .to_return(status: 200, body: File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml',
                                                          'cdb_init_response.xml')))
      stub_request(:post, 'https://194.180.18.30/ebicsweb/ebicsweb')
        .with(body: %r{<TransactionPhase>Transfer</TransactionPhase>})
        .to_return(status: 200, body: File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml',
                                                          'cdb_transfer_response.xml')))
    end

    it { expect(subject.CDB(cdb_document)).to eq(%w[387B7BE88FE33B0F4B60AC64A63F18E2 N00L]) }
  end

  describe '#CD1' do
    let(:cd1_document) { File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml', 'cd1.xml')) }
    describe 'normal behaviour' do
      before do
        stub_request(:post, 'https://194.180.18.30/ebicsweb/ebicsweb')
          .with(body: %r{<TransactionPhase>Initialisation</TransactionPhase>})
          .to_return(status: 200, body: File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml',
                                                            'cd1_init_response.xml')))
        stub_request(:post, 'https://194.180.18.30/ebicsweb/ebicsweb')
          .with(body: %r{<TransactionPhase>Transfer</TransactionPhase>})
          .to_return(status: 200, body: File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml',
                                                            'cd1_transfer_response.xml')))
      end

      it { expect(subject.CD1(cd1_document)).to eq(%w[387B7BE88FE33B0F4B60AC64A63F18E2 N00L]) }
    end

    describe 'special case' do
      before do
        stub_request(:post, 'https://194.180.18.30/ebicsweb/ebicsweb')
          .with(body: %r{<TransactionPhase>Initialisation</TransactionPhase>})
          .to_return(status: 200, body: File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml', 'cd1_init_response.xml')).sub(
            'N00L', 'N11L'
          ))
        stub_request(:post, 'https://194.180.18.30/ebicsweb/ebicsweb')
          .with(body: %r{<TransactionPhase>Transfer</TransactionPhase>})
          .to_return(status: 200, body: File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml', 'cd1_transfer_response.xml')).sub(
            '<OrderID>N00L</OrderID>', ''
          ))
      end

      # happend on some handelsbank accounts
      it 'can also try to fetch the order_id from the first transaction being made' do
        expect(subject.CD1(cd1_document)).to eq(%w[387B7BE88FE33B0F4B60AC64A63F18E2 N11L])
      end
    end
  end

  describe '#HTD' do
    before do
      allow(subject).to receive(:download).and_return(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml',
                                                                          'htd_order_data.xml')))
    end

    it 'sets @iban' do
      expect { subject.HTD }.to(change { subject.instance_variable_get('@iban') })
    end

    it 'sets @bic' do
      expect { subject.HTD }.to(change { subject.instance_variable_get('@bic') })
    end

    it 'sets @name' do
      expect { subject.HTD }.to(change { subject.instance_variable_get('@name') })
    end

    it 'sets @order_types' do
      expect { subject.HTD }.to(change { subject.instance_variable_get('@order_types') })
    end

    describe 'without iban' do
      before do
        allow(subject).to receive(:download).and_return(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml',
                                                                            'htd_order_data_without_names.xml')))
      end

      it 'sets @iban' do
        expect(subject.iban).to be_nil
      end
    end
  end

  describe '#C53/C52/C54/Z52/Z53/Z54 types with zipped data' do
    before do
      allow(subject).to receive(:download).and_return(File.read(File.join(File.dirname(__FILE__), 'fixtures',
                                                                          'test.zip')))
    end

    it 'will unzip the returned data' do
      %w[C52 C53 C54 Z52 Z53 Z54].each do |c|
        expect(subject.send(c, :today, :yesterday)).to eq(["ebics is great\n"])
      end
    end
  end

  describe '#C53/C52/C54/Z52/Z53/Z54 types with zipped data with general purpose bit flag 3 set' do
    before do
      allow(subject).to receive(:download).and_return(File.read(File.join(File.dirname(__FILE__), 'fixtures',
                                                                          'test_with_general_purpose_bit_3.zip')))
    end

    it 'will unzip the returned data' do
      %w[C52 C53 C54 Z52 Z53 Z54].each do |c|
        expect(subject.send(c, :today, :yesterday)).to eq(["ebics is great\n"])
      end
    end
  end

  describe '#x_509_certificate' do
    let(:epics_client) do
      Epics::Client.new(key, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS')
    end

    context 'with valid certificates content' do
      it 'returns an instance of Epics::X509Certificate' do
        epics_client.x_509_certificates_content = {
          a: generate_x_509_crt(epics_client.a.key, '/C=GB/O=TestOrg/CN=test.example.org'),
          x: generate_x_509_crt(epics_client.x.key, '/C=GB/O=TestOrg/CN=test.example.org'),
          e: generate_x_509_crt(epics_client.e.key, '/C=GB/O=TestOrg/CN=test.example.org')
        }

        expect(epics_client.x_509_certificate(:a)).to be_a(Epics::X509Certificate)
        expect(epics_client.x_509_certificate(:x)).to be_a(Epics::X509Certificate)
        expect(epics_client.x_509_certificate(:e)).to be_a(Epics::X509Certificate)
      end
    end

    context 'with nil or empty content' do
      it 'returns nil when content is nil' do
        epics_client.x_509_certificates_content = { a: nil, x: nil, e: nil }
        expect(epics_client.x_509_certificate(:a)).to be_nil
        expect(epics_client.x_509_certificate(:x)).to be_nil
        expect(epics_client.x_509_certificate(:e)).to be_nil
      end

      it 'returns nil when content is empty string' do
        epics_client.x_509_certificates_content = { a: '', x: '', e: '' }
        expect(epics_client.x_509_certificate(:a)).to be_nil
        expect(epics_client.x_509_certificate(:x)).to be_nil
        expect(epics_client.x_509_certificate(:e)).to be_nil
      end
    end
  end

  describe '#x_509_certificate_hash' do
    let(:epics_client) do
      Epics::Client.new(key, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS')
    end
    context 'with valid certificates content' do
      it 'returns SHA256 hash' do
        epics_client.x_509_certificates_content = {
          a: generate_x_509_crt(epics_client.a.key, '/C=GB/O=TestOrg/CN=test.example.org'),
          x: generate_x_509_crt(epics_client.x.key, '/C=GB/O=TestOrg/CN=test.example.org'),
          e: generate_x_509_crt(epics_client.e.key, '/C=GB/O=TestOrg/CN=test.example.org')
        }

        expect(epics_client.x_509_certificate_hash(:a)).to be_a(String)
        expect(epics_client.x_509_certificate_hash(:x)).to be_a(String)
        expect(epics_client.x_509_certificate_hash(:e)).to be_a(String)
        expect(epics_client.x_509_certificate_hash(:a).size).to eq(64)
        expect(epics_client.x_509_certificate_hash(:x).size).to eq(64)
        expect(epics_client.x_509_certificate_hash(:e).size).to eq(64)
      end
    end

    context 'with nil or empty content' do
      it 'returns nil when content is nil' do
        epics_client.x_509_certificates_content = { a: nil, x: nil, e: nil }
        expect(epics_client.x_509_certificate_hash(:a)).to be_nil
        expect(epics_client.x_509_certificate_hash(:x)).to be_nil
        expect(epics_client.x_509_certificate_hash(:e)).to be_nil
      end

      it 'returns nil when content is empty string' do
        epics_client.x_509_certificates_content = { a: '', x: '', e: '' }
        expect(epics_client.x_509_certificate_hash(:a)).to be_nil
        expect(epics_client.x_509_certificate_hash(:x)).to be_nil
        expect(epics_client.x_509_certificate_hash(:e)).to be_nil
      end
    end
  end
end

RSpec.describe Epics::HIA do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }

  subject { described_class.new(client) }

  describe 'order attributes' do
    let(:version) { Epics::Keyring::VERSION_25 }

    it { expect(subject.to_xml).to include('<OrderAttribute>DZNNN</OrderAttribute>') }
    it { expect(subject.to_xml).to include('<OrderType>HIA</OrderType>') }
  end

  include_examples '#to_xml'

  describe '#to_xml' do
    let(:version) { Epics::Keyring::VERSION_25 }

    describe 'validate against fixture' do
      let(:hia) { Nokogiri::XML(File.read(File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', RUBY_ENGINE, 'hia.xml'))) }
      before { allow(Time).to receive(:now).and_return(Time.parse('2014-10-10T11:16:00Z')) }

      it 'will match exactly' do
        expect(Nokogiri::XML(subject.to_xml)).to be_equivalent_to(hia)
      end
    end
  end

  describe '#order_data' do
    let(:version) { Epics::Keyring::VERSION_25 }

    specify { expect(subject.order_data).to be_a_valid_ebics_doc(version) }

    describe 'validate against fixture' do
      let(:hia_request_order_data) { Nokogiri::XML(File.read(File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'hia_request_order_data.xml'))) }
      before { allow(Time).to receive(:now).and_return(Time.parse('2014-10-10T11:16:00Z')) }

      it 'will match exactly' do
        expect(Nokogiri::XML(subject.order_data)).to be_equivalent_to(hia_request_order_data)
      end
    end

    context 'with x509 certificate' do
      let(:client) do
        client = Epics::Client.new(File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS')
        client.keyring.user_authentication.certificate = Epics::Crypt::X509.new(generate_x_509_crt(client.authentication_key.key, '/C=GB/O=TestOrg/CN=test.example.org'))
        client.keyring.user_encryption.certificate = Epics::Crypt::X509.new(generate_x_509_crt(client.encryption_key.key, '/C=GB/O=TestOrg/CN=test.example.org'))
        client
      end

      it 'includes x509 certificate' do
        expect(subject.order_data).to include('<ds:X509IssuerName>/C=GB/O=TestOrg/CN=test.example.org</ds:X509IssuerName>')
        expect(subject.order_data).to include('<ds:X509SerialNumber>2</ds:X509SerialNumber>')
        expect(subject.order_data).to include("<ds:X509Certificate>#{client.keyring.user_authentication.certificate.data}</ds:X509Certificate>")
        expect(subject.order_data).to include("<ds:X509Certificate>#{client.keyring.user_encryption.certificate.data}</ds:X509Certificate>")
      end
    end
  end
end

RSpec.describe Epics::INI do
  subject { described_class.new(client) }
  
  let(:client) { Epics::Client.new(key, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:key) { File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')) }

  before { allow(subject).to receive(:timestamp) { '2014-10-10T11:16:00Z' } }

  describe '#to_xml' do
    specify { expect(subject.to_xml).to be_a_valid_ebics_doc }

    describe 'validate against fixture' do
      let(:signature_order_data) do
        Nokogiri::XML(File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', RUBY_ENGINE, 'ini.xml')))
      end

      it 'will match exactly' do
        expect(Nokogiri::XML(subject.to_xml)).to be_equivalent_to(signature_order_data)
      end
    end
  end

  describe '#key_signature' do
    specify { expect(subject.key_signature).to be_a_valid_ebics_doc }

    describe 'validate against fixture' do
      let(:signature_order_data) do
        Nokogiri::XML(File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml',
                                          'signature_pub_key_order_data.xml')))
      end

      it 'will match exactly' do
        expect(Nokogiri::XML(subject.key_signature)).to be_equivalent_to(signature_order_data)
      end
    end

    context 'with x509 certificate' do
      let(:client) do
        client = Epics::Client.new(key, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS')
        client.x_509_certificate_a_content = generate_x_509_crt(client.a.key, distinguished_name)
        client
      end
      let(:distinguished_name) { '/C=GB/O=TestOrg/CN=test.example.org' }

      it 'includes x509 certificate' do
        a_crt = Epics::X509Certificate.new(client.x_509_certificate_a_content)
        expect(subject.key_signature).to include('<ds:X509IssuerName>/C=GB/O=TestOrg/CN=test.example.org</ds:X509IssuerName>')
        expect(subject.key_signature).to include('<ds:X509SerialNumber>2</ds:X509SerialNumber>')
        expect(subject.key_signature).to include("<ds:X509Certificate>#{a_crt.data}</ds:X509Certificate>")
      end
    end
    
    context 'when EBICS version is 2.4' do
      let(:client) do
        Epics::Client.new(key, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', options)
      end
      let(:options) { {version: Epics::Keyring::VERSION_24} }
      
      it 'includes the correct OrderID in the headers' do
        expect(subject.header.to_xml).to include("<OrderID>A001</OrderID>")
      end
      
      it 'includes the correct urn schema and version' do
        expect(subject.to_xml).to include('xmlns="http://www.ebics.org/H003"')
        expect(subject.to_xml).to include('Version="H003"')
      end
    end
    
    context 'when EBICS version is 2.5' do
      it 'does not include the OrderID in the headers' do
        expect(subject.header.to_xml).not_to include("<OrderID>A001</OrderID>")
      end
      
      it 'includes the correct urn schema' do
        expect(subject.to_xml).to include('xmlns="urn:org:ebics:H004"')
        expect(subject.to_xml).to include('Version="H004"')
      end
    end
  end
end

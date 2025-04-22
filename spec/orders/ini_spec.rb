RSpec.describe Epics::INI do
  let(:client) { Epics::Client.new(key, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:key) { File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')) }
  before { allow(subject).to receive(:timestamp) { '2014-10-10T11:16:00Z' } }

  subject { described_class.new(client) }

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
  end
end

RSpec.describe Epics::HIA do
  let(:client) { Epics::Client.new(key, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }
  let(:key) { File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')) }

  subject { described_class.new(client) }

  describe '#to_xml' do
    specify { expect(subject.to_xml).to be_a_valid_ebics_doc }

    describe 'validate against fixture' do
      let(:hia) do
        Nokogiri::XML(File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', RUBY_ENGINE, 'hia.xml')))
      end

      it 'will match exactly' do
        expect(Nokogiri::XML(subject.to_xml)).to be_equivalent_to(hia)
      end
    end
  end

  describe '#order_data' do
    specify { expect(subject.order_data).to be_a_valid_ebics_doc }

    describe 'validate against fixture' do
      let(:hia_request_order_data) do
        Nokogiri::XML(File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml',
                                          'hia_request_order_data.xml')))
      end

      it 'will match exactly' do
        expect(Nokogiri::XML(subject.order_data)).to be_equivalent_to(hia_request_order_data)
      end
    end

    context 'with x509 certificate' do
      let(:client) do
        client = Epics::Client.new(key, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS')
        client.x_509_certificates_content = {
          x: generate_x_509_crt(client.x.key, '/C=GB/O=TestOrg/CN=test.example.org'),
          e: generate_x_509_crt(client.e.key, '/C=GB/O=TestOrg/CN=test.example.org')
        }
        client
      end

      it 'includes x509 certificate' do
        x_crt = Epics::X509Certificate.new(client.x_509_certificates_content[:x])
        e_crt = Epics::X509Certificate.new(client.x_509_certificates_content[:e])
        expect(subject.order_data).to include('<ds:X509IssuerName>/C=GB/O=TestOrg/CN=test.example.org</ds:X509IssuerName>')
        expect(subject.order_data).to include('<ds:X509SerialNumber>2</ds:X509SerialNumber>')
        expect(subject.order_data).to include("<ds:X509Certificate>#{x_crt.data}</ds:X509Certificate>")
        expect(subject.order_data).to include("<ds:X509Certificate>#{e_crt.data}</ds:X509Certificate>")
      end
    end
  end
end

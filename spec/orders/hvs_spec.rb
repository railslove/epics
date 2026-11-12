RSpec.describe Epics::HVS do
  let(:key_file) { File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')) }
  let(:client) do
    Epics::Client.new(key_file, 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS',
                      version:)
  end
  let(:digest) { Digest::SHA256.digest('pain.001 waiting in the EDS') }
  let(:xml) { Nokogiri::XML(subject.to_xml) }

  subject { described_class.new(client, order_id: 'N02A', service: service, digest: digest) }

  describe 'H005' do
    let(:version) { Epics::Keyring::VERSION_30 }
    let(:service) { { service_name: 'SCT', service_option: 'VOI', msg_name: 'pain.001' } }
    let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

    include_examples '#to_xml', versions: [Epics::Keyring::VERSION_30]
    include_examples 'a valid ebicsRequest H005 header', admin_order_type: 'HVS'

    it 'identifies the order by partner, service and order ID' do
      params = xml.at_xpath('//e:OrderDetails/e:HVSOrderParams', ns)
      expect(params.at_xpath('e:PartnerID', ns).text).to eq('EBICS')
      expect(params.at_xpath('e:Service/e:ServiceName', ns).text).to eq('SCT')
      expect(params.at_xpath('e:Service/e:ServiceOption', ns).text).to eq('VOI')
      expect(params.at_xpath('e:Service/e:MsgName', ns).text).to eq('pain.001')
      expect(params.at_xpath('e:OrderID', ns).text).to eq('N02A')
    end

    it 'sends no order data' do
      expect(xml.at_xpath('//e:header/e:static/e:NumSegments', ns).text).to eq('0')
      expect(xml.at_xpath('//e:body/e:DataTransfer/e:OrderData', ns)).to be_nil
    end

    it 'carries the signature and the DataDigest it covers' do
      expect(xml.at_xpath('//e:body/e:DataTransfer/e:SignatureData', ns)).not_to be_nil
      data_digest = xml.at_xpath('//e:body/e:DataTransfer/e:DataDigest', ns)
      expect(Base64.strict_decode64(data_digest.text)).to eq(digest)
      expect(data_digest['SignatureVersion']).to eq('A006')
    end
  end

  describe 'H004' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:service) { 'CTV' }
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    include_examples '#to_xml', versions: [Epics::Keyring::VERSION_25]
    include_examples 'a valid ebicsRequest header', order_type: 'HVS', order_attribute: 'UZHNN'

    it 'identifies the order by partner, order type and order ID' do
      params = xml.at_xpath('//e:OrderDetails/e:HVSOrderParams', ns)
      expect(params.at_xpath('e:PartnerID', ns).text).to eq('EBICS')
      expect(params.at_xpath('e:OrderType', ns).text).to eq('CTV')
      expect(params.at_xpath('e:OrderID', ns).text).to eq('N02A')
    end

    # H004 has no DataDigest element: the bank derives the digest from the waiting order.
    it 'sends only the signature' do
      expect(xml.at_xpath('//e:header/e:static/e:NumSegments', ns).text).to eq('0')
      expect(xml.at_xpath('//e:body/e:DataTransfer/e:SignatureData', ns)).not_to be_nil
      expect(xml.at_xpath('//e:body/e:DataTransfer/e:OrderData', ns)).to be_nil
      expect(xml.at_xpath('//e:body/e:DataTransfer/e:DataDigest', ns)).to be_nil
    end
  end
end

RSpec.describe Epics::FUL do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  let(:document) { File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'cd1.xml') ) }

  subject { described_class.new(client, document, file_format: 'pain.001.001.02') }

  describe 'order attributes' do
    let(:version) { Epics::Keyring::VERSION_25 }

    it { expect(subject.to_xml).to include('<OrderAttribute>DZHNN</OrderAttribute>') }
    it { expect(subject.to_xml).to include('<OrderType>FUL</OrderType>') }
    it { expect(subject.to_xml).to include('<FileFormat>pain.001.001.02</FileFormat>') }
  end

  include_examples '#to_xml pending', versions: [Epics::Keyring::VERSION_24], reason: 'H003 upload support not yet implemented'
  include_examples '#to_xml', versions: [Epics::Keyring::VERSION_25]
  include_examples '#to_xml pending', versions: [Epics::Keyring::VERSION_30], reason: 'FUL replaced by BTU in H005'
  include_examples '#to_transfer_xml pending', versions: [Epics::Keyring::VERSION_24], reason: 'H003 upload support not yet implemented'
  include_examples '#to_transfer_xml', versions: [Epics::Keyring::VERSION_25]
  include_examples '#to_transfer_xml pending', versions: [Epics::Keyring::VERSION_30], reason: 'FUL replaced by BTU in H005'

  describe 'H004 request structure' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    include_examples 'a valid H004 upload request with FULOrderParams',
      order_type: 'FUL', order_attribute: 'DZHNN', file_format: 'pain.001.001.02'
  end

  describe 'H004 transfer structure' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:xml) do
      subject.transaction_id = SecureRandom.hex(16)
      Nokogiri::XML(subject.to_transfer_xml)
    end
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    include_examples 'a valid H004 transfer request'
  end
end

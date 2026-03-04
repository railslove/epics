RSpec.describe Epics::CDB do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  let(:document) { File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'cdb.xml') ) }

  subject { described_class.new(client, document) }

  describe 'order attributes' do
    let(:version) { Epics::Keyring::VERSION_25 }

    it { expect(subject.to_xml).to include('<OrderAttribute>OZHNN</OrderAttribute>') }
    it { expect(subject.to_xml).to include('<OrderType>CDB</OrderType>') }
  end

  include_examples '#to_xml pending', versions: [Epics::Keyring::VERSION_24], reason: 'H003 upload support not yet implemented'
  include_examples '#to_xml', versions: [Epics::Keyring::VERSION_25]
  include_examples '#to_xml pending', versions: [Epics::Keyring::VERSION_30], reason: 'H005 certificate support not yet implemented'
  include_examples '#to_transfer_xml pending', versions: [Epics::Keyring::VERSION_24], reason: 'H003 upload support not yet implemented'
  include_examples '#to_transfer_xml', versions: [Epics::Keyring::VERSION_25]
  include_examples '#to_transfer_xml pending', versions: [Epics::Keyring::VERSION_30], reason: 'H005 certificate support not yet implemented'

  describe 'H004 request structure' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    include_examples 'a valid H004 upload request', order_type: 'CDB', order_attribute: 'OZHNN'
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

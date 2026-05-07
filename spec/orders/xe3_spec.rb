RSpec.describe Epics::XE3 do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  let(:document) { File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'swiss_direct_debit.xml') ) }

  subject { described_class.new(client, document) }

  describe 'order attributes' do
    let(:version) { Epics::Keyring::VERSION_25 }

    it { expect(subject.to_xml).to include('<OrderAttribute>OZHNN</OrderAttribute>') }
    it { expect(subject.to_xml).to include('<OrderType>XE3</OrderType>') }
  end

  include_examples '#to_xml'
  include_examples '#to_transfer_xml'

  describe 'H005 request structure' do
    let(:version) { Epics::Keyring::VERSION_30 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

    include_examples 'a valid ebicsRequest H005 upload',
      service_name: 'SDD', msg_name: 'pain.008'
  end

  describe 'H005 transfer structure' do
    let(:version) { Epics::Keyring::VERSION_30 }
    let(:xml) do
      subject.transaction_id = SecureRandom.hex(16)
      Nokogiri::XML(subject.to_transfer_xml)
    end
    let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

    include_examples 'a valid ebicsRequest H005 transfer'
  end

  describe 'H004 request structure' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    include_examples 'a valid ebicsRequest upload', order_type: 'XE3', order_attribute: 'OZHNN'
  end

  describe 'H004 transfer structure' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:xml) do
      subject.transaction_id = SecureRandom.hex(16)
      Nokogiri::XML(subject.to_transfer_xml)
    end
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    include_examples 'a valid ebicsRequest transfer'
  end

  describe 'H003 request structure' do
    let(:version) { Epics::Keyring::VERSION_24 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

    include_examples 'a valid ebicsRequest upload', order_type: 'XE3', order_attribute: 'OZHNN', ebics_version: 'H003'
  end

  describe 'H003 transfer structure' do
    let(:version) { Epics::Keyring::VERSION_24 }
    let(:xml) do
      subject.transaction_id = SecureRandom.hex(16)
      Nokogiri::XML(subject.to_transfer_xml)
    end
    let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

    include_examples 'a valid ebicsRequest transfer', ebics_version: 'H003'
  end
end

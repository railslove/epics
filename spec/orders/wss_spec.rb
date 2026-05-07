RSpec.describe Epics::WSS do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }

  subject { described_class.new(client) }

  describe 'order attributes' do
    let(:version) { Epics::Keyring::VERSION_25 }

    it { expect(subject.to_xml).to include('<OrderAttribute>DZHNN</OrderAttribute>') }
    it { expect(subject.to_xml).to include('<OrderType>WSS</OrderType>') }
  end

  include_examples '#to_xml', versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25]

  describe '#to_xml H005' do
    let(:version) { Epics::Keyring::VERSION_30 }
    it('raises VersionSupportError') { expect { subject.to_xml }.to raise_error(Epics::VersionSupportError) }
  end

  describe 'H004 request structure' do
    let(:version) { Epics::Keyring::VERSION_25 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

    include_examples 'a valid ebicsRequest download', order_type: 'WSS'
  end

  describe 'H003 request structure' do
    let(:version) { Epics::Keyring::VERSION_24 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

    include_examples 'a valid ebicsRequest download', order_type: 'WSS', ebics_version: 'H003'
  end
end

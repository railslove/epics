RSpec.describe Epics::CCS do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  let(:document) { File.read( File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'cd1.xml') ) }

  subject { described_class.new(client, document) }

  describe 'order attributes' do
    let(:version) { Epics::Keyring::VERSION_25 }

    it { expect(subject.to_xml).to include('<OrderAttribute>DZHNN</OrderAttribute>') }
    it { expect(subject.to_xml).to include('<OrderType>CCS</OrderType>') }
  end

  include_examples '#to_xml', versions: [Epics::Keyring::VERSION_25]
  include_examples '#to_transfer_xml'
end

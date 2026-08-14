RSpec.describe Epics::ZSR do
  let(:client) do
    Epics::Client.new(File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')),
                      'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS',
                      version: version)
  end

  subject { described_class.new(client, from: Date.parse('2026-01-01'), to: Date.parse('2026-01-31')) }

  include_examples '#to_xml', versions: [Epics::Keyring::VERSION_30]

  describe 'H005 request structure' do
    let(:version) { Epics::Keyring::VERSION_30 }
    let(:xml) { Nokogiri::XML(subject.to_xml) }
    let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

    include_examples 'a valid ebicsRequest H005 download with date range',
                     service_name: 'PSR', msg_name: 'pain.002', scope: 'BIL',
                     from: '2026-01-01', to: '2026-01-31'
  end

  [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25].each do |older|
    describe older do
      let(:version) { older }

      it 'raises' do
        expect { subject.to_xml }.to raise_error(Epics::VersionSupportError, 'Supported from version 3.0')
      end
    end
  end
end

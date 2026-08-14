RSpec.describe Epics::VersionSupportError do
  let(:client) do
    Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')),
                      'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS',
                      version: version)
  end
  let(:document) { File.read(File.join(File.dirname(__FILE__), 'fixtures', 'xml', 'cd1.xml')) }

  describe 'a 2.x-only order type on H005' do
    let(:version) { Epics::Keyring::VERSION_30 }

    it 'reports the direction it means' do
      expect { Epics::FUL.new(client, document, file_format: 'x').to_xml }
        .to raise_error(described_class, 'Support for versions below 3.0')
    end

    # `raise Class, arg, backtrace` puts a third argument in the backtrace slot, so a
    # direction passed that way is silently dropped and the trace destroyed.
    it 'keeps its backtrace' do
      Epics::FUL.new(client, document, file_format: 'x').to_xml
    rescue described_class => e
      expect(e.backtrace.first).to include('request_factory/v3.rb')
    end
  end

  # "below 3.0" is only accurate if these work on 2.4 as well as 2.5.
  describe 'the 2.x-only order types' do
    builders = {
      'FUL' => ->(c, doc) { Epics::FUL.new(c, doc, file_format: 'pain.001') },
      'FDL' => ->(c, _doc) { Epics::FDL.new(c, file_format: 'camt.053') },
      'CD1' => ->(c, doc) { Epics::CD1.new(c, doc) },
      'WSS' => ->(c, _doc) { Epics::WSS.new(c) },
      'XDS' => ->(c, doc) { Epics::XDS.new(c, doc) },
      'XCT' => ->(c, doc) { Epics::XCT.new(c, doc) }
    }

    builders.each do |type, build|
      [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25].each do |supported|
        context "#{type} on #{supported}" do
          let(:version) { supported }

          it 'builds a request' do
            expect { build.call(client, document).to_xml }.not_to raise_error
          end
        end
      end

      context "#{type} on #{Epics::Keyring::VERSION_30}" do
        let(:version) { Epics::Keyring::VERSION_30 }

        it 'raises' do
          expect { build.call(client, document).to_xml }
            .to raise_error(described_class, 'Support for versions below 3.0')
        end
      end
    end
  end

  describe 'an H005-only concept on 2.x' do
    let(:version) { Epics::Keyring::VERSION_25 }

    it 'reports the direction it means' do
      expect { Epics::CCT.new(client, document).request_factory.create_btd }
        .to raise_error(described_class, 'Supported from version 3.0')
    end
  end

  describe 'an unknown direction' do
    let(:version) { Epics::Keyring::VERSION_25 }

    it 'raises rather than rendering a wrong message' do
      expect { described_class.new(3.0, 'sideways') }
        .to raise_error(ArgumentError, /Invalid direction/)
    end
  end
end

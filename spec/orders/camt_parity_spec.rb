RSpec.describe 'C52/C53/C54 parameter parity' do
  let(:client) do
    Epics::Client.new(File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')),
                      'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS',
                      version: version)
  end
  let(:range) { { from: Date.new(2026, 1, 1), to: Date.new(2026, 1, 31) } }
  let(:ns) { { 'e' => 'urn:org:ebics:H005' } }

  # The three camt statement retrievals differ only in service name and message type.
  types = { Epics::C52 => { service: 'STM', msg: 'camt.052' },
            Epics::C53 => { service: 'EOP', msg: 'camt.053' },
            Epics::C54 => { service: 'REP', msg: 'camt.054' } }

  def service(order, ns)
    Nokogiri::XML(order.to_xml).at_xpath('//e:Service', ns)
  end

  types.each do |type, expected|
    describe type do
      context 'on H005' do
        let(:version) { Epics::Keyring::VERSION_30 }

        it 'defaults to its own service and a ZIP container' do
          node = service(type.new(client, **range), ns)

          expect(node.at_xpath('e:ServiceName', ns).text).to eq(expected[:service])
          expect(node.at_xpath('e:MsgName', ns).text).to eq(expected[:msg])
          expect(node.at_xpath('e:Container', ns)['containerType']).to eq('ZIP')
          expect(node.at_xpath('e:Scope', ns)).to be_nil
        end

        it 'accepts scope' do
          node = service(type.new(client, **range, scope: 'CH'), ns)

          expect(node.at_xpath('e:Scope', ns).text).to eq('CH')
        end

        it 'accepts msg_name_version' do
          node = service(type.new(client, **range, msg_name_version: '08'), ns)

          expect(node.at_xpath('e:MsgName', ns)['version']).to eq('08')
        end

        it 'accepts container_type' do
          node = service(type.new(client, **range, container_type: 'XML'), ns)

          expect(node.at_xpath('e:Container', ns)['containerType']).to eq('XML')
        end
      end

      # H003/H004 address the same data by order type, so the BTF parameters have
      # nowhere to go and are ignored rather than rejected.
      [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25].each do |older|
        context "on #{older}" do
          let(:version) { older }

          it 'ignores the H005 service parameters' do
            expect { type.new(client, **range, scope: 'CH', container_type: 'XML').to_xml }
              .not_to raise_error
          end
        end
      end
    end
  end

  describe 'Epics::Client' do
    let(:version) { Epics::Keyring::VERSION_30 }

    # C54 took only from/to while its two siblings took three more options.
    it 'exposes the same keywords on all three' do
      %i[C52 C53 C54].each do |method|
        keywords = Epics::Client.instance_method(method).parameters
                                .select { |kind, _| kind == :key }.map(&:last)

        expect(keywords).to match_array(%i[scope msg_name_version container_type])
      end
    end
  end
end

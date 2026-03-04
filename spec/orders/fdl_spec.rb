RSpec.describe Epics::FDL do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  let(:file_format) { 'camt.xxx.cfonb120.stm.Oby' }

  context 'with file_format' do
    subject(:order) { described_class.new(client, file_format: file_format) }

    include_examples '#to_xml', versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25]
    describe '#to_xml H005' do
      let(:version) { Epics::Keyring::VERSION_30 }
      it('raises VersionSupportError') { expect { subject.to_xml }.to raise_error(Epics::VersionSupportError) }
    end
    include_examples '#to_receipt_xml', versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25]

    describe '#to_xml' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it 'does includes a date range as standard order parameter' do
        expect(order.to_xml).to include('<FDLOrderParams><FileFormat>camt.xxx.cfonb120.stm.Oby</FileFormat></FDLOrderParams>')
      end
    end

    describe 'H004 request structure' do
      let(:version) { Epics::Keyring::VERSION_25 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

      include_examples 'a valid ebicsRequest download with FDLOrderParams',
        order_type: 'FDL', file_format: 'camt.xxx.cfonb120.stm.Oby'
    end

    describe 'H004 receipt structure' do
      let(:version) { Epics::Keyring::VERSION_25 }
      let(:xml) do
        subject.transaction_id = SecureRandom.hex(16)
        Nokogiri::XML(subject.to_receipt_xml)
      end
      let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

      include_examples 'a valid ebicsRequest receipt'
    end

    describe 'H003 request structure' do
      let(:version) { Epics::Keyring::VERSION_24 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

      include_examples 'a valid ebicsRequest download with FDLOrderParams',
        order_type: 'FDL', file_format: 'camt.xxx.cfonb120.stm.Oby', ebics_version: 'H003'
    end

    describe 'H003 receipt structure' do
      let(:version) { Epics::Keyring::VERSION_24 }
      let(:xml) do
        subject.transaction_id = SecureRandom.hex(16)
        Nokogiri::XML(subject.to_receipt_xml)
      end
      let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

      include_examples 'a valid ebicsRequest receipt', ebics_version: 'H003'
    end

    context 'with DateRange' do
      subject(:order) { described_class.new(client, file_format: file_format, from: Date.new(2024, 1, 1), to: Date.new(2024, 1, 2)) }

      include_examples '#to_xml', versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25]
      describe '#to_xml H005' do
      let(:version) { Epics::Keyring::VERSION_30 }
      it('raises VersionSupportError') { expect { subject.to_xml }.to raise_error(Epics::VersionSupportError) }
    end
      include_examples '#to_receipt_xml', versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25]
  
      describe '#to_xml' do
        let(:version) { Epics::Keyring::VERSION_25 }

        it 'does includes a date range as optional order parameter' do
          expect(order.to_xml).to include('<FDLOrderParams><DateRange><Start>2024-01-01</Start><End>2024-01-02</End></DateRange><FileFormat>camt.xxx.cfonb120.stm.Oby</FileFormat></FDLOrderParams>')
        end
      end

      describe 'H004 request structure' do
        let(:version) { Epics::Keyring::VERSION_25 }
        let(:xml) { Nokogiri::XML(subject.to_xml) }
        let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

        include_examples 'a valid ebicsRequest download with FDLOrderParams and date range',
          order_type: 'FDL', file_format: 'camt.xxx.cfonb120.stm.Oby',
          from: '2024-01-01', to: '2024-01-02'
      end

      describe 'H004 receipt structure' do
        let(:version) { Epics::Keyring::VERSION_25 }
        let(:xml) do
          subject.transaction_id = SecureRandom.hex(16)
          Nokogiri::XML(subject.to_receipt_xml)
        end
        let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

        include_examples 'a valid ebicsRequest receipt'
      end

      describe 'H003 request structure' do
        let(:version) { Epics::Keyring::VERSION_24 }
        let(:xml) { Nokogiri::XML(subject.to_xml) }
        let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

        include_examples 'a valid ebicsRequest download with FDLOrderParams and date range',
          order_type: 'FDL', file_format: 'camt.xxx.cfonb120.stm.Oby',
          from: '2024-01-01', to: '2024-01-02', ebics_version: 'H003'
      end

      describe 'H003 receipt structure' do
        let(:version) { Epics::Keyring::VERSION_24 }
        let(:xml) do
          subject.transaction_id = SecureRandom.hex(16)
          Nokogiri::XML(subject.to_receipt_xml)
        end
        let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

        include_examples 'a valid ebicsRequest receipt', ebics_version: 'H003'
      end
    end
  end

  context 'without file_format' do
    subject(:order) { described_class.new(client) }

    describe 'order attributes' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it { expect(subject.to_xml).to include('<OrderAttribute>DZHNN</OrderAttribute>') }
      it { expect(subject.to_xml).to include('<OrderType>FDL</OrderType>') }
    end

    include_examples '#to_xml', versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25]
    describe '#to_xml H005' do
      let(:version) { Epics::Keyring::VERSION_30 }
      it('raises VersionSupportError') { expect { subject.to_xml }.to raise_error(Epics::VersionSupportError) }
    end
    include_examples '#to_receipt_xml', versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25]

    describe '#to_xml' do
      let(:version) { Epics::Keyring::VERSION_25 }

      it 'does not include a standard order parameter' do
        expect(order.to_xml).to include('<FDLOrderParams><FileFormat/></FDLOrderParams>')
      end
    end

    describe 'H004 request structure' do
      let(:version) { Epics::Keyring::VERSION_25 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

      include_examples 'a valid ebicsRequest download', order_type: 'FDL'
    end

    describe 'H004 receipt structure' do
      let(:version) { Epics::Keyring::VERSION_25 }
      let(:xml) do
        subject.transaction_id = SecureRandom.hex(16)
        Nokogiri::XML(subject.to_receipt_xml)
      end
      let(:ns) { { 'e' => 'urn:org:ebics:H004' } }

      include_examples 'a valid ebicsRequest receipt'
    end

    describe 'H003 request structure' do
      let(:version) { Epics::Keyring::VERSION_24 }
      let(:xml) { Nokogiri::XML(subject.to_xml) }
      let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

      include_examples 'a valid ebicsRequest download', order_type: 'FDL', ebics_version: 'H003'
    end

    describe 'H003 receipt structure' do
      let(:version) { Epics::Keyring::VERSION_24 }
      let(:xml) do
        subject.transaction_id = SecureRandom.hex(16)
        Nokogiri::XML(subject.to_receipt_xml)
      end
      let(:ns) { { 'e' => 'http://www.ebics.org/H003' } }

      include_examples 'a valid ebicsRequest receipt', ebics_version: 'H003'
    end
  end
end

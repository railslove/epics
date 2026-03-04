RSpec.describe 'RequestFactory' do
  let(:client) { Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  let(:start_date) { Date.new(2024, 1, 1) }
  let(:end_date) { Date.new(2024, 1, 31) }
  let(:digest) { OpenSSL::Digest::SHA256.digest('test document') }
  let(:transaction_key) { OpenSSL::Cipher::AES.new(128, :CBC).random_key }
  let(:transaction_id) { SecureRandom.hex(16) }

  def parse(builder)
    Nokogiri::XML(builder.to_xml).tap(&:remove_namespaces!)
  end

  # ─── Shared examples ───────────────────────────────────────

  shared_examples 'a base factory' do |factory_class|
    subject(:factory) { factory_class.new(client) }

    describe '#create_hev' do
      it 'creates ebicsHEVRequest with HostID' do
        xml = parse(factory.create_hev)
        expect(xml.root.name).to eq('ebicsHEVRequest')
        expect(xml.at('//HostID').text).to eq('SIZBN001')
      end
    end

    describe '#create_ini' do
      it 'creates ebicsUnsecuredRequest with INI order details' do
        xml = parse(factory.create_ini('<order_data/>'))
        expect(xml.root.name).to eq('ebicsUnsecuredRequest')
        expect(xml.at('//HostID').text).to eq('SIZBN001')
        expect(xml.at('//PartnerID').text).to eq(client.partner_id)
        expect(xml.at('//UserID').text).to eq(client.user_id)
        expect(xml.at('//SecurityMedium').text).to eq('0000')
      end
    end

    describe '#create_hia' do
      it 'creates ebicsUnsecuredRequest with HIA order details' do
        xml = parse(factory.create_hia('<order_data/>'))
        expect(xml.root.name).to eq('ebicsUnsecuredRequest')
        expect(xml.at('//HostID').text).to eq('SIZBN001')
      end
    end

    describe '#create_hpb' do
      it 'creates ebicsNoPubKeyDigestsRequest with AuthSignature' do
        xml = parse(factory.create_hpb)
        expect(xml.root.name).to eq('ebicsNoPubKeyDigestsRequest')
        expect(xml.at('//AuthSignature')).not_to be_nil
        expect(xml.at('//SecurityMedium').text).to eq('0000')
      end
    end

    describe '#create_transfer_receipt' do
      it 'creates receipt with TransactionID and ReceiptCode' do
        xml = parse(factory.create_transfer_receipt(transaction_id, 0))
        expect(xml.root.name).to eq('ebicsRequest')
        expect(xml.at('//TransactionID').text).to eq(transaction_id)
        expect(xml.at('//TransactionPhase').text).to eq('Receipt')
        expect(xml.at('//ReceiptCode').text).to eq('0')
        expect(xml.at('//AuthSignature')).not_to be_nil
      end
    end

    describe '#create_transfer_upload' do
      it 'creates transfer with segment data' do
        xml = parse(factory.create_transfer_upload(transaction_id, transaction_key, 'order_data', 1, true))
        expect(xml.at('//TransactionID').text).to eq(transaction_id)
        expect(xml.at('//TransactionPhase').text).to eq('Transfer')
        node = xml.at('//SegmentNumber')
        expect(node.text).to eq('1')
        expect(node['lastSegment']).to eq('true')
        expect(xml.at('//OrderData')).not_to be_nil
      end
    end

    describe '#create_transfer_download' do
      it 'creates transfer without order data' do
        xml = parse(factory.create_transfer_download(transaction_id, 2, false))
        expect(xml.at('//TransactionID').text).to eq(transaction_id)
        expect(xml.at('//TransactionPhase').text).to eq('Transfer')
        expect(xml.at('//SegmentNumber').text).to eq('2')
      end
    end

    describe 'admin order types' do
      %w[hpd hkd htd haa].each do |order_type|
        it "creates #{order_type.upcase} request with AuthSignature" do
          xml = parse(factory.send("create_#{order_type}"))
          expect(xml.root.name).to eq('ebicsRequest')
          expect(xml.at('//AuthSignature')).not_to be_nil
          expect(xml.at('//TransactionPhase').text).to eq('Initialisation')
          expect(xml.at('//BankPubKeyDigests')).not_to be_nil
        end
      end

      %w[hac ptk].each do |order_type|
        it "creates #{order_type.upcase} request with date range" do
          xml = parse(factory.send("create_#{order_type}", start_date, end_date))
          expect(xml.at('//AuthSignature')).not_to be_nil
          expect(xml.at('//DateRange/Start').text).to eq('2024-01-01')
          expect(xml.at('//DateRange/End').text).to eq('2024-01-31')
        end
      end
    end
  end

  # ─── V2 shared examples ────────────────────────────────────

  shared_examples 'a V2 download factory' do |factory_class, namespace|
    subject(:factory) { factory_class.new(client) }

    describe 'download requests' do
      download_types = {
        'c52' => {}, 'c53' => {}, 'c54' => {}, 'sta' => {},
        'vmk' => {}, 'z52' => {}, 'z53' => {}, 'z54' => {},
        'bka' => {}, 'c5n' => {}, 'cdz' => {}, 'crz' => {}, 'z01' => {}
      }

      download_types.each do |order_type, _|
        it "creates #{order_type.upcase} download request" do
          xml = parse(factory.send("create_#{order_type}", start_date, end_date))
          expect(xml.root.name).to eq('ebicsRequest')
          expect(xml.at('//OrderType').text).to eq(order_type.upcase)
          expect(xml.at('//OrderAttribute').text).to eq('DZHNN')
          expect(xml.at('//AuthSignature')).not_to be_nil
          expect(xml.at('//BankPubKeyDigests')).not_to be_nil
          expect(xml.at('//DateRange/Start').text).to eq('2024-01-01')
        end
      end
    end

    describe 'WSS download (no date range)' do
      it 'creates WSS request without date range' do
        xml = parse(factory.create_wss)
        expect(xml.at('//OrderType').text).to eq('WSS')
        expect(xml.at('//DateRange')).to be_nil
      end
    end

    describe 'FDL download with file format' do
      it 'creates FDL request with FDLOrderParams' do
        xml = parse(factory.create_fdl('camt.053', start_date, end_date))
        expect(xml.at('//OrderType').text).to eq('FDL')
        expect(xml.at('//FDLOrderParams/FileFormat').text).to eq('camt.053')
      end
    end
  end

  shared_examples 'a V2 upload factory' do |factory_class|
    subject(:factory) { factory_class.new(client) }

    describe 'upload requests' do
      upload_types_with_es = {
        'cct' => true, 'cdd' => true, 'cdb' => true, 'cip' => true,
        'cd1' => true, 'b2b' => true, 'xds' => true, 'xe2' => true, 'xe3' => true
      }
      upload_types_without_es = {
        'ccs' => false, 'cds' => false, 'c2s' => false
      }

      (upload_types_with_es.merge(upload_types_without_es)).each do |order_type, with_es|
        expected_attr = with_es ? 'OZHNN' : 'DZHNN'
        it "creates #{order_type.upcase} upload with OrderAttribute=#{expected_attr}" do
          xml = parse(factory.send("create_#{order_type}", digest, transaction_key))
          expect(xml.root.name).to eq('ebicsRequest')
          expect(xml.at('//OrderType').text).to eq(order_type.upcase)
          expect(xml.at('//OrderAttribute').text).to eq(expected_attr)
          expect(xml.at('//NumSegments').text).to eq('1')
          expect(xml.at('//SignatureData')).not_to be_nil
          expect(xml.at('//DataEncryptionInfo')).not_to be_nil
          expect(xml.at('//TransactionKey')).not_to be_nil
          expect(xml.at('//AuthSignature')).not_to be_nil
        end
      end
    end

    describe 'FUL upload with file format' do
      it 'creates FUL request with FULOrderParams' do
        xml = parse(factory.send(:create_ful, digest, transaction_key, file_format: 'pain.001.001.02'))
        expect(xml.at('//OrderType').text).to eq('FUL')
        expect(xml.at('//FULOrderParams/FileFormat').text).to eq('pain.001.001.02')
      end
    end

    describe 'VersionSupportError for V3-only types' do
      it 'raises for create_btd' do
        expect { factory.create_btd }.to raise_error(Epics::VersionSupportError)
      end

      it 'raises for create_btu' do
        expect { factory.create_btu }.to raise_error(Epics::VersionSupportError)
      end
    end
  end

  # ─── V24 (H003) ────────────────────────────────────────────

  describe Epics::Factories::RequestFactory::V24 do
    let(:version) { Epics::Keyring::VERSION_24 }

    include_examples 'a base factory', Epics::Factories::RequestFactory::V24
    include_examples 'a V2 download factory', Epics::Factories::RequestFactory::V24, 'http://www.ebics.org/H003'
    include_examples 'a V2 upload factory', Epics::Factories::RequestFactory::V24

    subject(:factory) { described_class.new(client) }

    describe 'V24-specific: OrderID present' do
      it 'includes OrderID in download requests' do
        xml = parse(factory.create_c52(start_date, end_date))
        expect(xml.at('//OrderID')).not_to be_nil
      end

      it 'includes OrderID in upload requests' do
        xml = parse(factory.create_cct(digest, transaction_key))
        expect(xml.at('//OrderID')).not_to be_nil
      end
    end

    describe 'INI uses DZNNN attribute' do
      it 'sets OrderAttribute to DZNNN for INI' do
        xml = parse(factory.create_ini('<data/>'))
        expect(xml.at('//OrderAttribute').text).to eq('DZNNN')
      end
    end

    describe 'NotImplementedError for unsupported types' do
      %w[xek yct zsr].each do |type|
        it "raises NotImplementedError for #{type}" do
          expect { factory.send("create_#{type}", start_date, end_date) }.to raise_error(NotImplementedError)
        end
      end
    end

    describe 'XML namespace' do
      it 'uses H003 namespace' do
        builder = factory.create_hev
        xml = Nokogiri::XML(builder.to_xml)
        # HEV uses H000, so check a standard request
        builder2 = factory.create_hpb
        xml2 = Nokogiri::XML(builder2.to_xml)
        expect(xml2.root.namespace.href).to eq('http://www.ebics.org/H003')
      end
    end
  end

  # ─── V25 (H004) ────────────────────────────────────────────

  describe Epics::Factories::RequestFactory::V25 do
    let(:version) { Epics::Keyring::VERSION_25 }

    include_examples 'a base factory', Epics::Factories::RequestFactory::V25
    include_examples 'a V2 download factory', Epics::Factories::RequestFactory::V25, 'urn:org:ebics:H004'
    include_examples 'a V2 upload factory', Epics::Factories::RequestFactory::V25

    subject(:factory) { described_class.new(client) }

    describe 'V25-specific: no OrderID' do
      it 'does not include OrderID in download requests' do
        xml = parse(factory.create_c52(start_date, end_date))
        expect(xml.at('//OrderID')).to be_nil
      end
    end

    describe 'XML namespace' do
      it 'uses H004 namespace' do
        builder = factory.create_hpb
        xml = Nokogiri::XML(builder.to_xml)
        expect(xml.root.namespace.href).to eq('urn:org:ebics:H004')
      end
    end
  end

  # ─── V3 (H005) ────────────────────────────────────────────

  describe Epics::Factories::RequestFactory::V3 do
    let(:version) { Epics::Keyring::VERSION_30 }

    include_examples 'a base factory', Epics::Factories::RequestFactory::V3

    subject(:factory) { described_class.new(client) }

    describe 'XML namespace' do
      it 'uses H005 namespace' do
        builder = factory.create_hpb
        xml = Nokogiri::XML(builder.to_xml)
        expect(xml.root.namespace.href).to eq('urn:org:ebics:H005')
      end
    end

    describe 'uses AdminOrderType instead of OrderType' do
      it 'generates AdminOrderType for admin requests' do
        xml = parse(factory.create_hpd)
        expect(xml.at('//AdminOrderType').text).to eq('HPD')
        expect(xml.at('//OrderType')).to be_nil
        expect(xml.at('//OrderAttribute')).to be_nil
        expect(xml.at('//OrderID')).to be_nil
      end
    end

    describe 'BTD download requests' do
      btd_downloads = {
        'c52' => { service_name: 'STM', msg_name: 'camt.052' },
        'c53' => { service_name: 'EOP', msg_name: 'camt.053', container_type: 'ZIP' },
        'c54' => { service_name: 'REP', msg_name: 'camt.054', container_type: 'ZIP' },
        'sta' => { service_name: 'EOP', msg_name: 'mt940' },
        'vmk' => { service_name: 'STM', msg_name: 'mt942' },
        'z52' => { service_name: 'STM', msg_name: 'camt.052', container_type: 'ZIP' },
        'z53' => { service_name: 'EOP', msg_name: 'camt.053', container_type: 'ZIP' },
        'z54' => { service_name: 'EOP', msg_name: 'camt.054', service_option: 'XQRR' },
        'xek' => { service_name: 'EOP', msg_name: 'pdf', container_type: 'ZIP' },
        'z01' => { service_name: 'PSR', msg_name: 'pain.002', service_option: 'CH003GEN' },
        'bka' => { service_name: 'EOP', msg_name: 'camt.053', scope: 'DE' },
        'c5n' => { service_name: 'STM', msg_name: 'camt.054', scope: 'DE', service_option: 'SCI' },
        'cdz' => { service_name: 'REP', msg_name: 'pain.002', scope: 'DE', service_option: 'SDD' },
        'crz' => { service_name: 'REP', msg_name: 'pain.002', scope: 'DE', service_option: 'SCT' },
        'zsr' => { service_name: 'PSR', msg_name: 'pain.002', scope: 'BIL' },
      }

      btd_downloads.each do |order_type, expected|
        it "creates #{order_type.upcase} as BTD with correct service params" do
          xml = parse(factory.send("create_#{order_type}", start_date, end_date))
          expect(xml.at('//AdminOrderType').text).to eq('BTD')
          expect(xml.at('//BTDOrderParams/Service/ServiceName').text).to eq(expected[:service_name])
          expect(xml.at('//BTDOrderParams/Service/MsgName').text).to eq(expected[:msg_name])

          if expected[:scope]
            expect(xml.at('//BTDOrderParams/Service/Scope').text).to eq(expected[:scope])
          else
            expect(xml.at('//BTDOrderParams/Service/Scope')).to be_nil
          end

          if expected[:service_option]
            expect(xml.at('//BTDOrderParams/Service/ServiceOption').text).to eq(expected[:service_option])
          end

          if expected[:container_type]
            expect(xml.at('//BTDOrderParams/Service/Container')['containerType']).to eq(expected[:container_type])
          end

          expect(xml.at('//AuthSignature')).not_to be_nil
          expect(xml.at('//BankPubKeyDigests')).not_to be_nil
        end
      end
    end

    describe 'BTU upload requests' do
      btu_uploads = {
        'cct' => { service_name: 'SCT', msg_name: 'pain.001', filename: 'cct.pain.001.xxx.xml' },
        'cdd' => { service_name: 'SDD', msg_name: 'pain.008', scope: 'GLB', service_option: 'COR', filename: 'cdd.pain.008.xxx.xml' },
        'cdb' => { service_name: 'SDD', msg_name: 'pain.008', service_option: 'B2B', filename: 'cdb.pain.008.xxx.xml' },
        'cip' => { service_name: 'SCI', msg_name: 'pain.001', filename: 'cip.pain.001.xxx.xml' },
        'xe2' => { service_name: 'MCT', msg_name: 'pain.001', filename: 'xe2.pain.001.xxx.xml' },
        'xe3' => { service_name: 'SDD', msg_name: 'pain.008', filename: 'xe3.pain.008.xxx.xml' },
        'yct' => { service_name: 'MCT', msg_name: 'pain.001', scope: 'BIL', filename: 'yct.pain.001.xxx.xml' },
        'azv' => { service_name: 'XCT', msg_name: 'dtazv', scope: 'DE', filename: 'azv.dtazv.xxx.xml' },
        'b2b' => { service_name: 'SDD', msg_name: 'pain.008', scope: 'BIL', service_option: 'B2B', filename: 'b2b.pain.008.xxx.xml' },
        'ccs' => { service_name: 'SCT', msg_name: 'pain.001', scope: 'DE', filename: 'ccs.pain.001.xxx.xml' },
        'cds' => { service_name: 'SDD', msg_name: 'pain.008', scope: 'BIL', filename: 'cds.pain.008.xxx.xml' },
        'c2s' => { service_name: 'SDD', msg_name: 'pain.008', scope: 'BIL', filename: 'c2s.pain.008.xxx.xml' },
      }

      btu_uploads.each do |order_type, expected|
        it "creates #{order_type.upcase} as BTU with correct service params" do
          xml = parse(factory.send("create_#{order_type}", digest, transaction_key))
          expect(xml.at('//AdminOrderType').text).to eq('BTU')
          params = xml.at('//BTUOrderParams')
          expect(params['fileName']).to eq(expected[:filename])
          expect(params.at('Service/ServiceName').text).to eq(expected[:service_name])
          expect(params.at('Service/MsgName').text).to eq(expected[:msg_name])

          if expected[:scope]
            expect(params.at('Service/Scope').text).to eq(expected[:scope])
          else
            expect(params.at('Service/Scope')).to be_nil
          end

          if expected[:service_option]
            expect(params.at('Service/ServiceOption').text).to eq(expected[:service_option])
          end

          # V3-specific upload elements
          expect(xml.at('//DataDigest')).not_to be_nil
          expect(xml.at('//AdditionalOrderInfo')).not_to be_nil
          expect(xml.at('//SignatureData')).not_to be_nil
          expect(xml.at('//DataEncryptionInfo')).not_to be_nil
          expect(xml.at('//AuthSignature')).not_to be_nil
          expect(xml.at('//NumSegments').text).to eq('1')
        end
      end
    end

    describe 'VersionSupportError for V2-only types' do
      %w[ful fdl cd1 wss xds].each do |type|
        it "raises VersionSupportError for #{type}" do
          expect { factory.send("create_#{type}", digest, transaction_key) }.to raise_error(Epics::VersionSupportError)
        end
      end
    end

    describe 'V3 upload includes DataDigest with correct SignatureVersion' do
      it 'DataDigest has SignatureVersion matching user signature' do
        xml = parse(factory.create_cct(digest, transaction_key))
        data_digest = xml.at('//DataDigest')
        expect(data_digest['SignatureVersion']).to eq(client.keyring.user_signature.version)
      end
    end
  end
end

RSpec.describe 'Builders' do
  # Helper to parse XML from a builder's doc
  def parse_doc(builder_instance)
    Nokogiri::XML(builder_instance.doc.to_xml)
  end

  describe Epics::Builders::XmlBuilder do
    shared_examples 'an XmlBuilder version' do |version_class, h00x_version, h00x_namespace|
      subject(:builder) { version_class.new }

      describe '#create_secured' do
        it "creates ebicsRequest with version #{h00x_version}" do
          builder.create_secured { |b| }
          xml = Nokogiri::XML(builder.to_xml)
          root = xml.root
          expect(root.name).to eq('ebicsRequest')
          expect(root['Version']).to eq(h00x_version)
          expect(root['Revision']).to eq('1')
          expect(root.namespace.href).to eq(h00x_namespace)
        end

        it 'includes ds namespace for secured requests' do
          builder.create_secured { |b| }
          xml = Nokogiri::XML(builder.to_xml)
          expect(xml.root.namespaces['xmlns:ds']).to eq('http://www.w3.org/2000/09/xmldsig#')
        end
      end

      describe '#create_unsecured' do
        it 'creates ebicsUnsecuredRequest without ds namespace' do
          builder.create_unsecured { |b| }
          xml = Nokogiri::XML(builder.to_xml)
          expect(xml.root.name).to eq('ebicsUnsecuredRequest')
          expect(xml.root.namespaces['xmlns:ds']).to be_nil
        end
      end

      describe '#create_secured_no_pubkey_digests' do
        it 'creates ebicsNoPubKeyDigestsRequest' do
          builder.create_secured_no_pubkey_digests { |b| }
          xml = Nokogiri::XML(builder.to_xml)
          expect(xml.root.name).to eq('ebicsNoPubKeyDigestsRequest')
          expect(xml.root.namespaces['xmlns:ds']).to eq('http://www.w3.org/2000/09/xmldsig#')
        end
      end

      describe '#create_unsigned' do
        it 'creates ebicsUnsignedRequest' do
          builder.create_unsigned { |b| }
          xml = Nokogiri::XML(builder.to_xml)
          expect(xml.root.name).to eq('ebicsUnsignedRequest')
        end
      end
    end

    context 'V24 (H003)' do
      include_examples 'an XmlBuilder version',
        Epics::Builders::XmlBuilder::V24, 'H003', 'http://www.ebics.org/H003'
    end

    context 'V25 (H004)' do
      include_examples 'an XmlBuilder version',
        Epics::Builders::XmlBuilder::V25, 'H004', 'urn:org:ebics:H004'
    end

    context 'V3 (H005)' do
      include_examples 'an XmlBuilder version',
        Epics::Builders::XmlBuilder::V3, 'H005', 'urn:org:ebics:H005'
    end

    describe '::Base#create_hev' do
      it 'creates ebicsHEVRequest with H000 namespace' do
        builder = Epics::Builders::XmlBuilder::V25.new
        builder.create_hev { |b| }
        xml = Nokogiri::XML(builder.to_xml)
        expect(xml.root.name).to eq('ebicsHEVRequest')
        expect(xml.root.namespace.href).to eq('http://www.ebics.org/H000')
      end
    end
  end

  describe Epics::Builders::MutableBuilder do
    it 'creates mutable element with TransactionPhase' do
      instance = described_class.new do |b|
        b.add_transaction_phase Epics::Builders::MutableBuilder::PHASE_INITIALIZATION
      end
      xml = parse_doc(instance)
      expect(xml.at('mutable/TransactionPhase').text).to eq('Initialisation')
    end

    it 'creates SegmentNumber with lastSegment attribute' do
      instance = described_class.new do |b|
        b.add_segment_number 3, true
      end
      xml = parse_doc(instance)
      node = xml.at('mutable/SegmentNumber')
      expect(node.text).to eq('3')
      expect(node['lastSegment']).to eq('true')
    end

    it 'creates ReceiptCode element' do
      instance = described_class.new do |b|
        b.add_receipt_code 0
      end
      xml = parse_doc(instance)
      expect(xml.at('mutable/ReceiptCode').text).to eq('0')
    end
  end

  describe Epics::Builders::TransferReceiptBuilder do
    it 'creates TransferReceipt with authenticate=true and ReceiptCode' do
      instance = described_class.new do |b|
        b.add_receipt_code 0
      end
      xml = parse_doc(instance)
      root = xml.root
      expect(root.name).to eq('TransferReceipt')
      expect(root['authenticate']).to eq('true')
      expect(root.at('ReceiptCode').text).to eq('0')
    end
  end

  describe Epics::Builders::OrderDetailsBuilder do
    describe '::V2' do
      it 'creates OrderType and OrderAttribute elements' do
        instance = described_class::V2.new do |b|
          b.add_order_type 'CCT'
          b.add_order_attribute 'DZHNN'
        end
        xml = parse_doc(instance)
        expect(xml.at('OrderDetails/OrderType').text).to eq('CCT')
        expect(xml.at('OrderDetails/OrderAttribute').text).to eq('DZHNN')
      end

      it 'raises VersionSupportError for add_admin_order_type' do
        expect {
          described_class::V2.new { |b| b.add_admin_order_type 'BTD' }
        }.to raise_error(Epics::VersionSupportError)
      end

      it 'raises VersionSupportError for add_btd_order_params' do
        expect {
          described_class::V2.new { |b| b.add_btd_order_params }
        }.to raise_error(Epics::VersionSupportError)
      end

      it 'raises VersionSupportError for add_btu_order_params' do
        expect {
          described_class::V2.new { |b| b.add_btu_order_params }
        }.to raise_error(Epics::VersionSupportError)
      end

      it 'creates StandardOrderParams with DateRange' do
        instance = described_class::V2.new do |b|
          b.add_standard_order_params(Date.new(2024, 1, 1), Date.new(2024, 1, 31))
        end
        xml = parse_doc(instance)
        expect(xml.at('StandardOrderParams/DateRange/Start').text).to eq('2024-01-01')
        expect(xml.at('StandardOrderParams/DateRange/End').text).to eq('2024-01-31')
      end

      it 'creates StandardOrderParams without DateRange' do
        instance = described_class::V2.new do |b|
          b.add_standard_order_params
        end
        xml = parse_doc(instance)
        expect(xml.at('StandardOrderParams')).not_to be_nil
        expect(xml.at('StandardOrderParams/DateRange')).to be_nil
      end

      it 'creates FDLOrderParams with FileFormat' do
        instance = described_class::V2.new do |b|
          b.add_fdl_order_params('camt.053')
        end
        xml = parse_doc(instance)
        expect(xml.at('FDLOrderParams/FileFormat').text).to eq('camt.053')
      end

      it 'creates FDLOrderParams with FileFormat and DateRange' do
        instance = described_class::V2.new do |b|
          b.add_fdl_order_params('camt.053', Date.new(2024, 1, 1), Date.new(2024, 1, 31))
        end
        xml = parse_doc(instance)
        expect(xml.at('FDLOrderParams/FileFormat').text).to eq('camt.053')
        expect(xml.at('FDLOrderParams/DateRange/Start').text).to eq('2024-01-01')
      end

      it 'creates FULOrderParams with FileFormat' do
        instance = described_class::V2.new do |b|
          b.add_ful_order_params('pain.001.001.02')
        end
        xml = parse_doc(instance)
        expect(xml.at('FULOrderParams/FileFormat').text).to eq('pain.001.001.02')
      end

      it 'creates OrderID in base36 uppercase right-justified' do
        instance = described_class::V2.new do |b|
          b.add_order_id(100)
        end
        xml = parse_doc(instance)
        expect(xml.at('OrderDetails/OrderID').text).to eq('002S')
      end
    end

    describe '::V3' do
      it 'creates AdminOrderType element' do
        instance = described_class::V3.new do |b|
          b.add_admin_order_type 'BTD'
        end
        xml = parse_doc(instance)
        expect(xml.at('OrderDetails/AdminOrderType').text).to eq('BTD')
      end

      it 'raises VersionSupportError for add_order_type' do
        expect {
          described_class::V3.new { |b| b.add_order_type 'CCT' }
        }.to raise_error(Epics::VersionSupportError)
      end

      it 'raises VersionSupportError for add_order_attribute' do
        expect {
          described_class::V3.new { |b| b.add_order_attribute 'DZHNN' }
        }.to raise_error(Epics::VersionSupportError)
      end

      describe '#add_btd_order_params' do
        it 'creates BTDOrderParams with Service structure' do
          instance = described_class::V3.new do |b|
            b.add_btd_order_params(
              service_name: 'EOP', msg_name: 'camt.053',
              container_type: 'ZIP', scope: 'DE', service_option: 'SCT'
            )
          end
          xml = parse_doc(instance)
          params = xml.at('OrderDetails/BTDOrderParams')
          expect(params).not_to be_nil
          expect(params.at('Service/ServiceName').text).to eq('EOP')
          expect(params.at('Service/Scope').text).to eq('DE')
          expect(params.at('Service/ServiceOption').text).to eq('SCT')
          expect(params.at('Service/Container')['containerType']).to eq('ZIP')
          expect(params.at('Service/MsgName').text).to eq('camt.053')
        end

        it 'omits optional fields when not provided' do
          instance = described_class::V3.new do |b|
            b.add_btd_order_params(service_name: 'STM', msg_name: 'camt.052')
          end
          xml = parse_doc(instance)
          params = xml.at('OrderDetails/BTDOrderParams')
          expect(params.at('Service/Scope')).to be_nil
          expect(params.at('Service/ServiceOption')).to be_nil
          expect(params.at('Service/Container')).to be_nil
          expect(params.at('DateRange')).to be_nil
        end

        it 'includes DateRange when dates provided' do
          instance = described_class::V3.new do |b|
            b.add_btd_order_params(
              service_name: 'EOP', msg_name: 'camt.053',
              start_date: Date.new(2024, 3, 1), end_date: Date.new(2024, 3, 31)
            )
          end
          xml = parse_doc(instance)
          expect(xml.at('BTDOrderParams/DateRange/Start').text).to eq('2024-03-01')
          expect(xml.at('BTDOrderParams/DateRange/End').text).to eq('2024-03-31')
        end

        it 'supports MsgName attributes' do
          instance = described_class::V3.new do |b|
            b.add_btd_order_params(
              service_name: 'EOP', msg_name: 'camt.053',
              msg_name_version: '08', msg_name_variant: 'gzip', msg_name_format: 'XML'
            )
          end
          xml = parse_doc(instance)
          msg = xml.at('BTDOrderParams/Service/MsgName')
          expect(msg['version']).to eq('08')
          expect(msg['variant']).to eq('gzip')
          expect(msg['format']).to eq('XML')
        end
      end

      describe '#add_btu_order_params' do
        it 'creates BTUOrderParams with fileName and Service' do
          instance = described_class::V3.new do |b|
            b.add_btu_order_params(
              filename: 'cct.pain.001.xxx.xml',
              service_name: 'SCT', msg_name: 'pain.001', scope: 'DE'
            )
          end
          xml = parse_doc(instance)
          params = xml.at('OrderDetails/BTUOrderParams')
          expect(params['fileName']).to eq('cct.pain.001.xxx.xml')
          expect(params.at('Service/ServiceName').text).to eq('SCT')
          expect(params.at('Service/Scope').text).to eq('DE')
          expect(params.at('Service/MsgName').text).to eq('pain.001')
        end

        it 'omits optional fields when not provided' do
          instance = described_class::V3.new do |b|
            b.add_btu_order_params(
              filename: 'test.xml', service_name: 'SCT', msg_name: 'pain.001'
            )
          end
          xml = parse_doc(instance)
          params = xml.at('OrderDetails/BTUOrderParams')
          expect(params.at('Service/Scope')).to be_nil
          expect(params.at('Service/ServiceOption')).to be_nil
          expect(params.at('Service/ContainerFlag')).to be_nil
        end
      end
    end
  end

  describe Epics::Builders::StaticBuilder do
    shared_examples 'a StaticBuilder' do |version_class|
      it 'creates static element with all standard fields' do
        timestamp = Time.utc(2024, 6, 15, 10, 30, 0)
        allow(SecureRandom).to receive(:hex).with(16).and_return('abcdef1234567890abcdef1234567890')

        instance = version_class.new do |b|
          b.add_host_id 'SIZBN001'
          b.add_random_nonce
          b.add_timestamp timestamp
          b.add_partner_id 'EBIX'
          b.add_user_id 'EBICS'
          b.add_product 'Epics', 'fr'
          b.add_security_medium '0000'
        end
        xml = parse_doc(instance)
        expect(xml.at('static/HostID').text).to eq('SIZBN001')
        expect(xml.at('static/Nonce').text).to eq('abcdef1234567890abcdef1234567890')
        expect(xml.at('static/Timestamp').text).to eq('2024-06-15T10:30:00Z')
        expect(xml.at('static/PartnerID').text).to eq('EBIX')
        expect(xml.at('static/UserID').text).to eq('EBICS')
        expect(xml.at('static/Product').text).to eq('Epics')
        expect(xml.at('static/Product')['Language']).to eq('fr')
        expect(xml.at('static/SecurityMedium').text).to eq('0000')
      end

      it 'creates BankPubKeyDigests with Base64-encoded digests' do
        instance = version_class.new do |b|
          b.add_bank_pubbey_digests('X002', 'auth_digest', 'E002', 'enc_digest')
        end
        xml = parse_doc(instance)
        auth = xml.at('static/BankPubKeyDigests/Authentication')
        enc = xml.at('static/BankPubKeyDigests/Encryption')
        expect(auth['Version']).to eq('X002')
        expect(auth['Algorithm']).to eq('http://www.w3.org/2001/04/xmlenc#sha256')
        expect(auth.text).to eq(Base64.strict_encode64('auth_digest'))
        expect(enc['Version']).to eq('E002')
        expect(enc.text).to eq(Base64.strict_encode64('enc_digest'))
      end

      it 'creates NumSegments element' do
        instance = version_class.new do |b|
          b.add_num_segments 5
        end
        xml = parse_doc(instance)
        expect(xml.at('static/NumSegments').text).to eq('5')
      end

      it 'creates TransactionID element' do
        instance = version_class.new do |b|
          b.add_transaction_id 'abc123'
        end
        xml = parse_doc(instance)
        expect(xml.at('static/TransactionID').text).to eq('abc123')
      end
    end

    describe '::V2' do
      include_examples 'a StaticBuilder', Epics::Builders::StaticBuilder::V2

      it 'delegates add_order_details to OrderDetailsBuilder::V2' do
        instance = Epics::Builders::StaticBuilder::V2.new do |b|
          b.add_order_details do |od|
            od.add_order_type 'CCT'
            od.add_order_attribute 'DZHNN'
          end
        end
        xml = parse_doc(instance)
        expect(xml.at('static/OrderDetails/OrderType').text).to eq('CCT')
        expect(xml.at('static/OrderDetails/OrderAttribute').text).to eq('DZHNN')
      end
    end

    describe '::V3' do
      include_examples 'a StaticBuilder', Epics::Builders::StaticBuilder::V3

      it 'delegates add_order_details to OrderDetailsBuilder::V3' do
        instance = Epics::Builders::StaticBuilder::V3.new do |b|
          b.add_order_details do |od|
            od.add_admin_order_type 'BTD'
            od.add_btd_order_params(service_name: 'EOP', msg_name: 'camt.053')
          end
        end
        xml = parse_doc(instance)
        expect(xml.at('static/OrderDetails/AdminOrderType').text).to eq('BTD')
        expect(xml.at('static/OrderDetails/BTDOrderParams/Service/ServiceName').text).to eq('EOP')
      end
    end
  end

  describe Epics::Builders::DataTransferBuilder do
    describe '::V2' do
      it 'add_data_digest is a no-op' do
        instance = described_class::V2.new do |b|
          result = b.add_data_digest('A005', 'some_digest')
          expect(result).to eq(b)
        end
        xml = parse_doc(instance)
        expect(xml.at('DataTransfer/DataDigest')).to be_nil
      end

      it 'add_additional_order_info is a no-op' do
        instance = described_class::V2.new do |b|
          result = b.add_additional_order_info
          expect(result).to eq(b)
        end
        xml = parse_doc(instance)
        expect(xml.at('DataTransfer/AdditionalOrderInfo')).to be_nil
      end
    end

    describe '::V3' do
      it 'add_data_digest creates DataDigest element with SignatureVersion' do
        digest = OpenSSL::Digest::SHA256.digest('test')
        instance = described_class::V3.new do |b|
          b.add_data_digest('A006', digest)
        end
        xml = parse_doc(instance)
        node = xml.at('DataTransfer/DataDigest')
        expect(node).not_to be_nil
        expect(node['SignatureVersion']).to eq('A006')
        expect(node.text).to eq(Base64.strict_encode64(digest))
      end

      it 'add_additional_order_info creates AdditionalOrderInfo element' do
        instance = described_class::V3.new do |b|
          b.add_additional_order_info
        end
        xml = parse_doc(instance)
        expect(xml.at('DataTransfer/AdditionalOrderInfo')).not_to be_nil
      end
    end

    describe 'shared behavior (V2 and V3)' do
      [Epics::Builders::DataTransferBuilder::V2, Epics::Builders::DataTransferBuilder::V3].each do |klass|
        context klass.name do
          it 'add_order_data compresses and Base64-encodes data' do
            instance = klass.new do |b|
              b.add_order_data('hello world')
            end
            xml = parse_doc(instance)
            order_data = xml.at('DataTransfer/OrderData')
            expect(order_data).not_to be_nil
            decoded = Base64.strict_decode64(order_data.text)
            decompressed = Zlib::Inflate.inflate(decoded)
            expect(decompressed).to eq('hello world')
          end

          it 'add_order_data compresses, encrypts, and Base64-encodes with transaction key' do
            crypt = Epics::Services::CryptService.new
            transaction_key = OpenSSL::Cipher::AES.new(128, :CBC).random_key
            instance = klass.new do |b|
              b.add_order_data('secret data', transaction_key)
            end
            xml = parse_doc(instance)
            decoded = Base64.strict_decode64(xml.at('DataTransfer/OrderData').text)
            decrypted = crypt.decrypt_by_key(transaction_key, decoded)
            decompressed = Zlib::Inflate.inflate(decrypted)
            expect(decompressed).to eq('secret data')
          end

          it 'add_signature_data compresses, encrypts, and Base64-encodes' do
            crypt = Epics::Services::CryptService.new
            transaction_key = OpenSSL::Cipher::AES.new(128, :CBC).random_key
            instance = klass.new do |b|
              b.add_signature_data('<SignatureData>test</SignatureData>', transaction_key)
            end
            xml = parse_doc(instance)
            node = xml.at('DataTransfer/SignatureData')
            expect(node['authenticate']).to eq('true')
            decoded = Base64.strict_decode64(node.text)
            decrypted = crypt.decrypt_by_key(transaction_key, decoded)
            decompressed = Zlib::Inflate.inflate(decrypted)
            expect(decompressed).to eq('<SignatureData>test</SignatureData>')
          end
        end
      end
    end
  end

  describe Epics::Builders::DataEncryptionInfoBuilder do
    let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
    let(:rsa_algo) { Epics::SignatureAlgorithm::Rsa.new(rsa_key) }
    let(:keyring) do
      kr = double('keyring')
      bank_enc = Epics::Signature.new(Epics::Signature::E_VERSION_2, rsa_algo)
      allow(kr).to receive(:bank_encryption).and_return(bank_enc)
      kr
    end

    it 'creates DataEncryptionInfo with authenticate=true' do
      instance = described_class.new do |b|
        b.add_encryption_pubkey_digest(keyring)
        b.add_transaction_key(SecureRandom.random_bytes(16), keyring)
      end
      xml = parse_doc(instance)
      root = xml.root
      expect(root.name).to eq('DataEncryptionInfo')
      expect(root['authenticate']).to eq('true')
    end

    it 'creates EncryptionPubKeyDigest with version and algorithm' do
      instance = described_class.new do |b|
        b.add_encryption_pubkey_digest(keyring)
      end
      xml = parse_doc(instance)
      node = xml.at('DataEncryptionInfo/EncryptionPubKeyDigest')
      expect(node['Version']).to eq('E002')
      expect(node['Algorithm']).to eq('http://www.w3.org/2001/04/xmlenc#sha256')
      expect(node.text).not_to be_empty
    end

    it 'creates TransactionKey that can be decrypted with private key' do
      transaction_key = SecureRandom.random_bytes(16)
      instance = described_class.new do |b|
        b.add_transaction_key(transaction_key, keyring)
      end
      xml = parse_doc(instance)
      encrypted_b64 = xml.at('DataEncryptionInfo/TransactionKey').text
      decrypted = rsa_key.private_decrypt(Base64.strict_decode64(encrypted_b64))
      expect(decrypted).to eq(transaction_key)
    end
  end

  describe Epics::Builders::HeaderBuilder do
    describe '::V2' do
      it 'creates header with authenticate=true' do
        instance = Epics::Builders::HeaderBuilder::V2.new do |b|
          b.add_mutable do |m|
            m.add_transaction_phase 'Initialisation'
          end
        end
        xml = parse_doc(instance)
        expect(xml.root.name).to eq('header')
        expect(xml.root['authenticate']).to eq('true')
        expect(xml.at('header/mutable/TransactionPhase').text).to eq('Initialisation')
      end
    end

    describe '::V3' do
      it 'creates header with authenticate=true using V3 static builder' do
        instance = Epics::Builders::HeaderBuilder::V3.new do |b|
          b.add_static do |s|
            s.add_host_id 'TESTHOST'
          end
        end
        xml = parse_doc(instance)
        expect(xml.root.name).to eq('header')
        expect(xml.at('header/static/HostID').text).to eq('TESTHOST')
      end
    end
  end

  describe Epics::Builders::BodyBuilder do
    describe '::V2' do
      it 'creates body element' do
        instance = Epics::Builders::BodyBuilder::V2.new { |b| }
        xml = parse_doc(instance)
        expect(xml.root.name).to eq('body')
      end

      it 'delegates add_transfer_receipt to TransferReceiptBuilder' do
        instance = Epics::Builders::BodyBuilder::V2.new do |b|
          b.add_transfer_receipt do |r|
            r.add_receipt_code 0
          end
        end
        xml = parse_doc(instance)
        expect(xml.at('body/TransferReceipt/ReceiptCode').text).to eq('0')
        expect(xml.at('body/TransferReceipt')['authenticate']).to eq('true')
      end
    end

    describe '::V3' do
      it 'creates body element' do
        instance = Epics::Builders::BodyBuilder::V3.new { |b| }
        xml = parse_doc(instance)
        expect(xml.root.name).to eq('body')
      end

      it 'delegates add_data_transfer to DataTransferBuilder::V3' do
        instance = Epics::Builders::BodyBuilder::V3.new do |b|
          b.add_data_transfer do |dt|
            dt.add_additional_order_info
          end
        end
        xml = parse_doc(instance)
        expect(xml.at('body/DataTransfer/AdditionalOrderInfo')).not_to be_nil
      end
    end
  end
end

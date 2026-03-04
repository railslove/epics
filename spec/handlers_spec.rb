RSpec.describe 'Handlers' do
  let(:client) { Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }
  let(:version) { Epics::Keyring::VERSION_25 }

  describe Epics::Handlers::UserSignatureHandler do
    let(:digest) { OpenSSL::Digest::SHA256.digest('test document') }

    describe '::Base' do
      it 'raises NotImplementedError' do
        base = described_class::Base.new(client)
        expect { base.handle(digest) }.to raise_error(NotImplementedError)
      end
    end

    describe '::V2' do
      subject(:handler) { described_class::V2.new(client) }

      it 'generates UserSignatureData with S001 namespace' do
        result = handler.handle(digest)
        xml = Nokogiri::XML(result.to_xml)
        expect(xml.root.name).to eq('UserSignatureData')
        expect(xml.root.namespace.href).to eq('http://www.ebics.org/S001')
      end

      it 'includes OrderSignatureData with correct structure' do
        result = handler.handle(digest)
        xml = Nokogiri::XML(result.to_xml)
        xml.remove_namespaces!
        expect(xml.at('//SignatureVersion').text).to eq(client.keyring.user_signature.version)
        expect(xml.at('//PartnerID').text).to eq(client.partner_id)
        expect(xml.at('//UserID').text).to eq(client.user_id)
      end

      it 'produces a verifiable SignatureValue' do
        result = handler.handle(digest)
        xml = Nokogiri::XML(result.to_xml)
        xml.remove_namespaces!
        sig_value = xml.at('//SignatureValue').text
        expect(client.keyring.user_signature.key.verify(sig_value, digest)).to be true
      end
    end

    describe '::V3' do
      let(:version) { Epics::Keyring::VERSION_30 }
      subject(:handler) { described_class::V3.new(client) }

      it 'generates UserSignatureData with S002 namespace' do
        result = handler.handle(digest)
        xml = Nokogiri::XML(result.to_xml)
        expect(xml.root.name).to eq('UserSignatureData')
        expect(xml.root.namespace.href).to eq('http://www.ebics.org/S002')
      end

      it 'includes OrderSignatureData with correct structure' do
        result = handler.handle(digest)
        xml = Nokogiri::XML(result.to_xml)
        xml.remove_namespaces!
        expect(xml.at('//SignatureVersion').text).to eq(client.keyring.user_signature.version)
        expect(xml.at('//PartnerID').text).to eq(client.partner_id)
        expect(xml.at('//UserID').text).to eq(client.user_id)
      end

      it 'produces a verifiable SignatureValue' do
        result = handler.handle(digest)
        xml = Nokogiri::XML(result.to_xml)
        xml.remove_namespaces!
        sig_value = xml.at('//SignatureValue').text
        expect(client.keyring.user_signature.key.verify(sig_value, digest)).to be true
      end
    end

    describe 'V2 vs V3 namespace difference' do
      let(:digest) { OpenSSL::Digest::SHA256.digest('test') }

      it 'V2 uses S001, V3 uses S002' do
        v2_client = Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version: Epics::Keyring::VERSION_25)
        v3_client = Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')), 'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version: Epics::Keyring::VERSION_30)

        v2_xml = Nokogiri::XML(described_class::V2.new(v2_client).handle(digest).to_xml)
        v3_xml = Nokogiri::XML(described_class::V3.new(v3_client).handle(digest).to_xml)
        expect(v2_xml.root.namespace.href).to eq('http://www.ebics.org/S001')
        expect(v3_xml.root.namespace.href).to eq('http://www.ebics.org/S002')
      end
    end
  end

  describe Epics::Handlers::OrderDataHandler do
    let(:timestamp) { Time.utc(2024, 6, 15, 10, 30, 0) }

    shared_examples 'an OrderDataHandler' do |handler_class, hia_namespace, sig_namespace|
      subject(:handler) { handler_class.new(client) }

      describe '#handle_ini' do
        it 'generates SignaturePubKeyOrderData XML' do
          handler.handle_ini(client.keyring.user_signature, timestamp)
          xml = Nokogiri::XML(handler.to_xml)
          xml.remove_namespaces!
          expect(xml.at('SignaturePubKeyOrderData')).not_to be_nil
        end

        it "uses #{sig_namespace} namespace" do
          handler.handle_ini(client.keyring.user_signature, timestamp)
          xml = Nokogiri::XML(handler.to_xml)
          node = xml.root
          expect(node.namespace.href).to eq(sig_namespace)
        end

        it 'includes SignatureVersion' do
          handler.handle_ini(client.keyring.user_signature, timestamp)
          xml = Nokogiri::XML(handler.to_xml)
          xml.remove_namespaces!
          expect(xml.at('//SignatureVersion').text).to eq(client.keyring.user_signature.version)
        end

        it 'includes PartnerID and UserID' do
          handler.handle_ini(client.keyring.user_signature, timestamp)
          xml = Nokogiri::XML(handler.to_xml)
          xml.remove_namespaces!
          expect(xml.at('//PartnerID').text).to eq(client.partner_id)
          expect(xml.at('//UserID').text).to eq(client.user_id)
        end
      end

      describe '#handle_hia' do
        it 'generates HIARequestOrderData XML' do
          handler.handle_hia(client.keyring.user_authentication, client.keyring.user_encryption, timestamp)
          xml = Nokogiri::XML(handler.to_xml)
          xml.remove_namespaces!
          expect(xml.at('HIARequestOrderData')).not_to be_nil
        end

        it 'includes AuthenticationVersion and EncryptionVersion' do
          handler.handle_hia(client.keyring.user_authentication, client.keyring.user_encryption, timestamp)
          xml = Nokogiri::XML(handler.to_xml)
          xml.remove_namespaces!
          expect(xml.at('//AuthenticationVersion').text).to eq(client.keyring.user_authentication.version)
          expect(xml.at('//EncryptionVersion').text).to eq(client.keyring.user_encryption.version)
        end

        it 'includes PartnerID and UserID' do
          handler.handle_hia(client.keyring.user_authentication, client.keyring.user_encryption, timestamp)
          xml = Nokogiri::XML(handler.to_xml)
          xml.remove_namespaces!
          expect(xml.at('//PartnerID').text).to eq(client.partner_id)
          expect(xml.at('//UserID').text).to eq(client.user_id)
        end
      end
    end

    context 'V24 (H003)' do
      let(:version) { Epics::Keyring::VERSION_24 }
      include_examples 'an OrderDataHandler',
        Epics::Handlers::OrderDataHandler::V24, 'http://www.ebics.org/H003', 'http://www.ebics.org/S001'

      it 'includes PubKeyValue with RSA key material in INI' do
        handler = Epics::Handlers::OrderDataHandler::V24.new(client)
        handler.handle_ini(client.keyring.user_signature, timestamp)
        xml = Nokogiri::XML(handler.to_xml)
        xml.remove_namespaces!
        expect(xml.at('//RSAKeyValue/Modulus')).not_to be_nil
        expect(xml.at('//RSAKeyValue/Exponent')).not_to be_nil
        expect(xml.at('//PubKeyValue/TimeStamp').text).to eq('2024-06-15T10:30:00Z')
      end
    end

    context 'V25 (H004)' do
      let(:version) { Epics::Keyring::VERSION_25 }
      include_examples 'an OrderDataHandler',
        Epics::Handlers::OrderDataHandler::V25, 'urn:org:ebics:H004', 'http://www.ebics.org/S001'

      it 'includes PubKeyValue with RSA key material in HIA (2 keys)' do
        handler = Epics::Handlers::OrderDataHandler::V25.new(client)
        handler.handle_hia(client.keyring.user_authentication, client.keyring.user_encryption, timestamp)
        xml = Nokogiri::XML(handler.to_xml)
        xml.remove_namespaces!
        moduli = xml.xpath('//RSAKeyValue/Modulus')
        expect(moduli.size).to eq(2)
      end
    end

    context 'V3 (H005)' do
      let(:version) { Epics::Keyring::VERSION_30 }
      include_examples 'an OrderDataHandler',
        Epics::Handlers::OrderDataHandler::V3, 'urn:org:ebics:H005', 'http://www.ebics.org/S002'

      it 'does NOT include PubKeyValue (relies on certificates)' do
        handler = Epics::Handlers::OrderDataHandler::V3.new(client)
        handler.handle_ini(client.keyring.user_signature, timestamp)
        xml = Nokogiri::XML(handler.to_xml)
        xml.remove_namespaces!
        expect(xml.at('//PubKeyValue')).to be_nil
      end

      it 'includes X509Data when certificate is present' do
        handler = Epics::Handlers::OrderDataHandler::V3.new(client)
        handler.handle_ini(client.keyring.user_signature, timestamp)
        xml = Nokogiri::XML(handler.to_xml)
        xml.remove_namespaces!
        expect(xml.at('//X509Data')).not_to be_nil
        expect(xml.at('//X509Certificate')).not_to be_nil
      end
    end
  end

  describe Epics::Handlers::AuthSignatureHandler do
    it 'adds AuthSignature element to XML builder output' do
      hpb = Epics::HPB.new(client)
      xml = Nokogiri::XML(hpb.to_xml)
      xml.remove_namespaces!
      expect(xml.at('//AuthSignature')).not_to be_nil
    end

    it 'includes ds:SignedInfo with correct algorithms' do
      hpb = Epics::HPB.new(client)
      xml = Nokogiri::XML(hpb.to_xml)
      ds = { 'ds' => 'http://www.w3.org/2000/09/xmldsig#' }
      signed_info = xml.at_xpath('//ds:SignedInfo', ds)
      expect(signed_info).not_to be_nil

      canon_method = signed_info.at_xpath('ds:CanonicalizationMethod', ds)
      expect(canon_method['Algorithm']).to include('REC-xml-c14n-20010315')

      sig_method = signed_info.at_xpath('ds:SignatureMethod', ds)
      expect(sig_method['Algorithm']).to include('rsa-sha256')
    end

    it 'includes ds:DigestValue that matches header hash' do
      allow(SecureRandom).to receive(:hex).with(16).and_return('014a82626a51ee1cab547bbaf18a13a0')
      allow(Time).to receive(:now).and_return(Time.parse('2014-09-09T09:33:12Z'))

      hpb = Epics::HPB.new(client)
      xml = Nokogiri::XML(hpb.to_xml)

      headers_node = xml.xpath("//*[@authenticate='true']").first
      crypt_service = Epics::Services::CryptService.new
      expected_hash = crypt_service.hash(headers_node.canonicalize)

      ds = { 'ds' => 'http://www.w3.org/2000/09/xmldsig#' }
      digest_value = xml.at_xpath('//ds:DigestValue', ds).text
      expect(digest_value).to eq(Base64.strict_encode64(expected_hash))
    end

    it 'produces a verifiable ds:SignatureValue' do
      hpb = Epics::HPB.new(client)
      xml = Nokogiri::XML(hpb.to_xml)
      ds = { 'ds' => 'http://www.w3.org/2000/09/xmldsig#' }
      sig_value = xml.at_xpath('//ds:SignatureValue', ds).text
      signed_info = xml.at_xpath('//ds:SignedInfo', ds)
      expect(client.keyring.user_authentication.key.verify(sig_value, signed_info.canonicalize)).to be true
    end

    context 'with different EBICS versions' do
      [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25, Epics::Keyring::VERSION_30].each do |ver|
        it "works with version #{ver}" do
          c = Epics::Client.new(
            File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')),
            'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version: ver
          )
          hpb = Epics::HPB.new(c)
          xml = Nokogiri::XML(hpb.to_xml)
          xml.remove_namespaces!
          expect(xml.at('//AuthSignature')).not_to be_nil
        end
      end
    end
  end
end

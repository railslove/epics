RSpec.describe 'EBICS 3.0 (H005) client' do
  let(:client) do
    Epics::Client.new(
      File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')),
      'secret', 'https://example.com', 'SIZBN001', 'EBIX', 'EBICS',
      version: :h005
    )
  end

  describe 'version wiring' do
    it { expect(client.ebics_version).to eq(:h005) }
    it { expect(client.namespace).to eq('urn:org:ebics:H005') }
    it { expect(client.protocol_version).to eq('H005') }
    it { expect(client).to be_h005 }

    it 'defaults to H004 when no version is given' do
      c = Epics::Client.new(nil, 'secret', 'https://example.com', 'H', 'U', 'P')
      expect(c.ebics_version).to eq(:h004)
      expect(c.namespace).to eq('urn:org:ebics:H004')
      expect(c).not_to be_h005
    end

    it 'rejects unknown versions' do
      expect {
        Epics::Client.new(nil, 'secret', 'https://example.com', 'H', 'U', 'P', version: :h006)
      }.to raise_error(ArgumentError, /Unsupported EBICS version/)
    end
  end

  describe 'admin order types' do
    it { expect(Epics::HPB.new(client).to_xml).to include('<AdminOrderType>HPB</AdminOrderType>') }
    it { expect(Epics::HTD.new(client).to_xml).to include('<AdminOrderType>HTD</AdminOrderType>') }
    it { expect(Epics::HPB.new(client).to_xml).not_to include('OrderAttribute') }

    context 'XSD validity', if: ebics_xsd_available?(:h005) do
      %i[HPB HTD HAA HKD HPD].each do |ot|
        it "#{ot} is a valid H005 document" do
          expect(Epics.const_get(ot).new(client).to_xml).to be_a_valid_ebics_doc(:h005)
        end
      end

      it 'INI is a valid H005 document' do
        expect(Epics::INI.new(client).to_xml).to be_a_valid_ebics_doc(:h005)
      end

      it 'HIA is a valid H005 document' do
        expect(Epics::HIA.new(client).to_xml).to be_a_valid_ebics_doc(:h005)
      end
    end
  end

  describe 'key management embeds X.509 certificates (mandatory in H005)' do
    it 'embeds a self-signed cert in HIA order data' do
      data = Epics::HIA.new(client).order_data
      expect(data).to include('urn:org:ebics:H005')
      expect(data).to include('X509Certificate')
    end

    it 'embeds a self-signed cert in the INI signature order data' do
      expect(Epics::INI.new(client).key_signature).to include('X509Certificate')
    end

    it 'generates a certificate for each key type' do
      %i[a x e].each { |t| expect(client.x_509_certificate(t)).to be_a(Epics::X509Certificate) }
    end

    it 'uses the S002 signature namespace and no RSAKeyValue' do
      sig = Epics::INI.new(client).key_signature
      expect(sig).to include('http://www.ebics.org/S002')
      expect(sig).not_to include('RSAKeyValue')
    end

    context 'S002 XSD validity', if: ebics_xsd_available?(:h005) do
      let(:s002) do
        Nokogiri::XML::Schema(File.open(File.join(File.dirname(__FILE__), 'xsd', 'ebics_signature_S002.xsd')))
      end

      it 'INI signature order data validates against S002' do
        errors = s002.validate(Nokogiri::XML(Epics::INI.new(client).key_signature))
        expect(errors).to be_empty
      end
    end
  end

  describe 'HPB imports bank keys from X.509 certificates (H005)' do
    let(:bank_auth) { OpenSSL::PKey::RSA.generate(2048) }
    let(:bank_enc)  { OpenSSL::PKey::RSA.generate(2048) }

    def cert_data(rsa)
      Epics::X509Certificate.generate_self_signed(rsa, subject: '/CN=bank').data
    end

    let(:hpb_response) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <HPBResponseOrderData xmlns="urn:org:ebics:H005" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <AuthenticationPubKeyInfo>
            <ds:X509Data><ds:X509Certificate>#{cert_data(bank_auth)}</ds:X509Certificate></ds:X509Data>
            <AuthenticationVersion>X002</AuthenticationVersion>
          </AuthenticationPubKeyInfo>
          <EncryptionPubKeyInfo>
            <ds:X509Data><ds:X509Certificate>#{cert_data(bank_enc)}</ds:X509Certificate></ds:X509Data>
            <EncryptionVersion>E002</EncryptionVersion>
          </EncryptionPubKeyInfo>
          <HostID>SIZBN001</HostID>
        </HPBResponseOrderData>
      XML
    end

    before { allow(client).to receive(:download).with(Epics::HPB).and_return(hpb_response) }

    it 'stores the bank authentication key (X002) from its certificate' do
      client.HPB
      expect(client.bank_x).to be_a(Epics::Key)
      expect(client.bank_x.key.n).to eq(bank_auth.n)
    end

    it 'stores the bank encryption key (E002) from its certificate' do
      client.HPB
      expect(client.bank_e).to be_a(Epics::Key)
      expect(client.bank_e.key.n).to eq(bank_enc.n)
    end
  end

  describe 'convenience methods route to BTU/BTD under H005' do
    it 'CCT builds a BTU with the SCT service' do
      order = Epics::BTU.new(client, '<Document/>', service: Epics::BtfMapping.upload('CCT'))
      expect(order.header.to_s).to include('<AdminOrderType>BTU</AdminOrderType>')
      expect(order.header.to_s).to include('<ServiceName>SCT</ServiceName>')
    end
  end
end

RSpec.describe 'EBICS 2.5 (H004) remains the default and unchanged' do
  let(:client) do
    Epics::Client.new(
      File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')),
      'secret', 'https://example.com', 'SIZBN001', 'EBIX', 'EBICS'
    )
  end

  it 'still emits the classic OrderType/OrderAttribute shape' do
    header = Epics::CCT.new(client, '<Document/>').header.to_s
    expect(header).to include('<OrderType>CCT</OrderType>')
    expect(header).to include('<OrderAttribute>OZHNN</OrderAttribute>')
    expect(header).not_to include('AdminOrderType')
  end

  it 'does not auto-embed X.509 certificates' do
    expect(Epics::HIA.new(client).order_data).not_to include('X509Certificate')
  end
end

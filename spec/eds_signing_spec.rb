RSpec.describe 'Verification of Payee reports and EDS signing' do
  let(:url) { 'https://194.180.18.30/ebicsweb/ebicsweb' }
  let(:key_file) { File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')) }
  let(:ns) { { 'e' => client.urn_schema } }
  let(:digest) { Digest::SHA256.digest('pain.001 waiting in the EDS') }

  # The transaction key of our requests is random; fixing it lets the spec decrypt SignatureData.
  let(:request_transaction_key) { Base64.strict_decode64('NoG3dD6eHqtYTYrJn6TIzA==') }
  let(:response_transaction_key) { SecureRandom.random_bytes(16) }

  # Requests the bank received, in order, as parsed XML.
  let(:requests) { [] }
  let(:order_data) { raise 'define the order data the bank returns for HVD, HVU or VPZ' }

  before do
    allow_any_instance_of(OpenSSL::Cipher::AES).to receive(:random_key).and_return(request_transaction_key)

    stub_request(:post, url).to_return do |http_request|
      request = Nokogiri::XML(http_request.body)
      requests << request
      body = case order_type_of(request)
             when 'HVE', 'HVS' then signature_response
             else download_response(order_data)
             end
      { status: 200, body: body }
    end
  end

  def order_type_of(request)
    order_type = request.at_xpath('//e:OrderDetails/e:AdminOrderType', ns) ||
                 request.at_xpath('//e:OrderDetails/e:OrderType', ns)
    order_type.text
  end

  def download_response(data)
    cipher = OpenSSL::Cipher.new('aes-128-cbc').encrypt
    cipher.key = response_transaction_key
    encrypted = cipher.update(Zlib::Deflate.deflate(data)) + cipher.final

    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <ebicsResponse xmlns="#{client.urn_schema}" Version="#{client.version}" Revision="1">
        <header authenticate="true">
          <static><TransactionID>ECD6F062AAEDFA77250526A68CBEC549</TransactionID></static>
          <mutable><TransactionPhase>Initialisation</TransactionPhase><ReturnCode>000000</ReturnCode></mutable>
        </header>
        <body>
          <DataTransfer>
            <DataEncryptionInfo authenticate="true">
              <TransactionKey>#{Base64.strict_encode64(client.encryption_key.key.public_encrypt(response_transaction_key))}</TransactionKey>
            </DataEncryptionInfo>
            <OrderData>#{Base64.strict_encode64(encrypted)}</OrderData>
          </DataTransfer>
          <ReturnCode authenticate="true">000000</ReturnCode>
        </body>
      </ebicsResponse>
    XML
  end

  def signature_response
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <ebicsResponse xmlns="#{client.urn_schema}" Version="#{client.version}" Revision="1">
        <header authenticate="true">
          <static><TransactionID>387B7BE88FE33B0F4B60AC64A63F18E2</TransactionID></static>
          <mutable><TransactionPhase>Initialisation</TransactionPhase><OrderID>N00L</OrderID><ReturnCode>000000</ReturnCode></mutable>
        </header>
        <body><ReturnCode authenticate="true">000000</ReturnCode></body>
      </ebicsResponse>
    XML
  end

  def data_digest_element(base64_text)
    %(<DataDigest SignatureVersion="A006">#{base64_text}</DataDigest>)
  end

  def hvd_order_data(data_digest_xml)
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <HVDResponseOrderData xmlns="#{client.urn_schema}">
        #{data_digest_xml}
        <DisplayFile>#{Base64.strict_encode64('SCT 0,01 EUR')}</DisplayFile>
        <OrderDataAvailable>true</OrderDataAvailable>
        <OrderDetailsAvailable>true</OrderDetailsAvailable>
      </HVDResponseOrderData>
    XML
  end

  # SignatureData is the deflated UserSignatureData, encrypted with the request's transaction key.
  def signature_value_of(request, signature_namespace)
    encrypted = Base64.strict_decode64(request.at_xpath('//e:body/e:DataTransfer/e:SignatureData', ns).text)
    user_signature_data = Zlib::Inflate.inflate(
      Epics::Services::CryptService.new.decrypt_by_key(request_transaction_key, encrypted)
    )
    Nokogiri::XML(user_signature_data).at_xpath('//s:SignatureValue', 's' => signature_namespace).text
  end

  describe 'H004' do
    let(:client) do
      Epics::Client.new(key_file, 'secret', url, 'SIZBN001', 'EBIX', 'EBICS', version: Epics::Keyring::VERSION_25)
    end

    describe '#HVE' do
      let(:order_data) { hvd_order_data(data_digest_element(Base64.strict_encode64(digest))) }

      it 'fetches the order with HVD, then sends HVE for the same order' do
        expect(client.HVE('N02A', 'CTV')).to eq(%w[387B7BE88FE33B0F4B60AC64A63F18E2 N00L])

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVD HVE])
        expect(requests[0].at_xpath('//e:HVDOrderParams/e:OrderType', ns).text).to eq('CTV')
        expect(requests[0].at_xpath('//e:HVDOrderParams/e:OrderID', ns).text).to eq('N02A')
        expect(requests[1].at_xpath('//e:HVEOrderParams/e:OrderType', ns).text).to eq('CTV')
        expect(requests[1].at_xpath('//e:HVEOrderParams/e:OrderID', ns).text).to eq('N02A')
      end

      it 'signs the DataDigest the bank reports for the order' do
        client.HVE('N02A', 'CTV')

        signature_value = signature_value_of(requests[1], 'http://www.ebics.org/S001')
        expect(client.keyring.user_signature.key.verify(signature_value, digest)).to eq(true)
      end

      it 'signs when the expected digest matches' do
        expect(client.HVE('N02A', 'CTV', digest: digest)).to eq(%w[387B7BE88FE33B0F4B60AC64A63F18E2 N00L])

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVD HVE])
      end

      it 'sends no HVE when the expected digest differs' do
        expect { client.HVE('N02A', 'CTV', digest: Digest::SHA256.digest('another order')) }
          .to raise_error(Epics::DataDigestMismatchError, /N02A/)

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVD])
      end

      context 'when the bank reports no DataDigest' do
        let(:order_data) { hvd_order_data('') }

        it 'sends no HVE' do
          expect { client.HVE('N02A', 'CTV') }.to raise_error(Epics::InvalidResponseError, /DataDigest/)

          expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVD])
        end
      end

      context 'when the bank reports an empty DataDigest' do
        let(:order_data) { hvd_order_data(data_digest_element(' ')) }

        it 'sends no HVE' do
          expect { client.HVE('N02A', 'CTV') }.to raise_error(Epics::InvalidResponseError, /DataDigest/)

          expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVD])
        end
      end

      context 'when the bank wraps the Base64 DataDigest across lines' do
        let(:order_data) { hvd_order_data(data_digest_element(Base64.encode64(digest))) }

        it 'reads the digest and signs it' do
          expect(Base64.encode64(digest)).to include("\n")
          expect(client.HVE('N02A', 'CTV', digest: digest)).to eq(%w[387B7BE88FE33B0F4B60AC64A63F18E2 N00L])

          signature_value = signature_value_of(requests[1], 'http://www.ebics.org/S001')
          expect(client.keyring.user_signature.key.verify(signature_value, digest)).to eq(true)
        end
      end
    end

    describe '#HVS' do
      let(:order_data) { hvd_order_data(data_digest_element(Base64.strict_encode64(digest))) }

      it 'fetches the order with HVD, then sends HVS for the same order' do
        expect(client.HVS('N02A', 'CTV')).to eq(%w[387B7BE88FE33B0F4B60AC64A63F18E2 N00L])

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVD HVS])
        expect(requests[1].at_xpath('//e:HVSOrderParams/e:OrderType', ns).text).to eq('CTV')
        expect(requests[1].at_xpath('//e:HVSOrderParams/e:OrderID', ns).text).to eq('N02A')
      end

      it 'signs the DataDigest the bank reports for the order' do
        client.HVS('N02A', 'CTV')

        signature_value = signature_value_of(requests[1], 'http://www.ebics.org/S001')
        expect(client.keyring.user_signature.key.verify(signature_value, digest)).to eq(true)
      end

      it 'sends no HVS when the expected digest differs' do
        expect { client.HVS('N02A', 'CTV', digest: Digest::SHA256.digest('another order')) }
          .to raise_error(Epics::DataDigestMismatchError, /N02A/)

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVD])
      end
    end

    describe '#HVD' do
      let(:order_data) { hvd_order_data(data_digest_element(Base64.strict_encode64(digest))) }

      it 'returns the order data of the waiting order' do
        expect(client.HVD('N02A', 'CTV')).to eq(order_data)

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVD])
        expect(requests[0].at_xpath('//e:HVDOrderParams/e:OrderID', ns).text).to eq('N02A')
      end
    end

    describe '#HVU' do
      let(:order_data) { %(<HVUResponseOrderData xmlns="#{client.urn_schema}"/>) }

      it 'returns the list of waiting orders' do
        expect(client.HVU).to eq(order_data)

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVU])
      end
    end

    describe '#VPZ' do
      let(:order_data) { File.binread(File.join(File.dirname(__FILE__), 'fixtures', 'test.zip')) }

      it 'downloads the reports for the given range and unzips them' do
        expect(client.VPZ(Date.new(2026, 11, 1), Date.new(2026, 11, 11))).to eq(["ebics is great\n"])

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[VPZ])
        date_range = requests[0].at_xpath('//e:StandardOrderParams/e:DateRange', ns)
        expect(date_range.at_xpath('e:Start', ns).text).to eq('2026-11-01')
        expect(date_range.at_xpath('e:End', ns).text).to eq('2026-11-11')
      end
    end
  end

  describe 'H005' do
    let(:client) do
      Epics::Client.new(key_file, 'secret', url, 'SIZBN001', 'EBIX', 'EBICS', version: Epics::Keyring::VERSION_30)
    end
    let(:service) { { service_name: 'SCT', service_option: 'VOI', msg_name: 'pain.001' } }

    describe '#HVE' do
      let(:order_data) { hvd_order_data(data_digest_element(Base64.strict_encode64(digest))) }

      it 'fetches the order with HVD, then sends HVE for the same service and order' do
        expect(client.HVE('N02A', service)).to eq(%w[387B7BE88FE33B0F4B60AC64A63F18E2 N00L])

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVD HVE])
        expect(requests[0].at_xpath('//e:HVDOrderParams/e:Service/e:ServiceOption', ns).text).to eq('VOI')
        expect(requests[0].at_xpath('//e:HVDOrderParams/e:OrderID', ns).text).to eq('N02A')
        expect(requests[1].at_xpath('//e:HVEOrderParams/e:Service/e:ServiceOption', ns).text).to eq('VOI')
        expect(requests[1].at_xpath('//e:HVEOrderParams/e:OrderID', ns).text).to eq('N02A')
      end

      it 'signs the DataDigest the bank reports and sends it along' do
        client.HVE('N02A', service)

        signature_value = signature_value_of(requests[1], 'http://www.ebics.org/S002')
        expect(client.keyring.user_signature.key.verify(signature_value, digest)).to eq(true)
        data_digest = requests[1].at_xpath('//e:body/e:DataTransfer/e:DataDigest', ns)
        expect(Base64.strict_decode64(data_digest.text)).to eq(digest)
      end

      it 'sends no HVE when the expected digest differs' do
        expect { client.HVE('N02A', service, digest: Digest::SHA256.digest('another order')) }
          .to raise_error(Epics::DataDigestMismatchError, /N02A/)

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVD])
      end
    end

    describe '#HVS' do
      let(:order_data) { hvd_order_data(data_digest_element(Base64.strict_encode64(digest))) }

      it 'fetches the order with HVD, then sends HVS for the same service and order' do
        expect(client.HVS('N02A', service)).to eq(%w[387B7BE88FE33B0F4B60AC64A63F18E2 N00L])

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[HVD HVS])
        expect(requests[1].at_xpath('//e:HVSOrderParams/e:OrderID', ns).text).to eq('N02A')
      end

      it 'signs the DataDigest the bank reports and sends it along' do
        client.HVS('N02A', service)

        signature_value = signature_value_of(requests[1], 'http://www.ebics.org/S002')
        expect(client.keyring.user_signature.key.verify(signature_value, digest)).to eq(true)
        data_digest = requests[1].at_xpath('//e:body/e:DataTransfer/e:DataDigest', ns)
        expect(Base64.strict_decode64(data_digest.text)).to eq(digest)
      end
    end

    describe '#VPZ' do
      let(:order_data) { File.binread(File.join(File.dirname(__FILE__), 'fixtures', 'test.zip')) }

      it 'downloads the reports with BTD and unzips them' do
        expect(client.VPZ).to eq(["ebics is great\n"])

        expect(requests.map { |request| order_type_of(request) }).to eq(%w[BTD])
        expect(requests[0].at_xpath('//e:BTDOrderParams/e:Service/e:ServiceOption', ns).text).to eq('VOP')
      end
    end
  end
end

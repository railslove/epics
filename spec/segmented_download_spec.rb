RSpec.describe 'segmented downloads' do
  versions = [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25, Epics::Keyring::VERSION_30]

  let(:url) { 'https://194.180.18.30/ebicsweb/ebicsweb' }
  let(:version) { Epics::Keyring::VERSION_25 }
  let(:client) do
    Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')),
                      'secret', url, 'SIZBN001', 'EBIX', 'EBICS', version:)
  end
  let(:ns) { { 'e' => client.urn_schema } }
  let(:transaction_id) { 'ECD6F062AAEDFA77250526A68CBEC549' }

  describe 'Epics::GenericRequest#to_transfer_download_xml' do
    let(:order) { Epics::C53.new(client, from: Date.new(2026, 9, 24), to: Date.new(2026, 9, 24)) }
    let(:xml) { Nokogiri::XML(order.to_transfer_download_xml(2, false)) }

    before { order.transaction_id = transaction_id }

    versions.each do |version|
      context version do
        let(:version) { version }

        it 'is a valid EBICS document' do
          expect(xml.to_xml).to be_a_valid_ebics_doc(version)
        end

        it 'requests the segment of the transaction without sending order data' do
          expect(xml.at_xpath('//e:header/e:static/e:TransactionID', ns).text).to eq(transaction_id)
          expect(xml.at_xpath('//e:header/e:mutable/e:TransactionPhase', ns).text).to eq('Transfer')
          expect(xml.at_xpath('//e:header/e:mutable/e:SegmentNumber', ns).text).to eq('2')
          expect(xml.at_xpath('//e:header/e:mutable/e:SegmentNumber', ns)['lastSegment']).to eq('false')
          expect(xml.at_xpath('//e:body', ns).elements).to be_empty
        end
      end
    end

    it 'marks the last segment' do
      segment_number = Nokogiri::XML(order.to_transfer_download_xml(3, true))
                               .at_xpath('//e:header/e:mutable/e:SegmentNumber', ns)

      expect(segment_number.text).to eq('3')
      expect(segment_number['lastSegment']).to eq('true')
    end
  end

  describe 'Epics::Client#download' do
    def response(phase, order_data: nil, segment_number: nil, num_segments: nil, return_code: '000000')
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <ebicsResponse xmlns="#{client.urn_schema}" Version="#{version}" Revision="1">
          <header authenticate="true">
            <static>
              <TransactionID>#{transaction_id}</TransactionID>
              #{"<NumSegments>#{num_segments}</NumSegments>" if num_segments}
            </static>
            <mutable>
              <TransactionPhase>#{phase}</TransactionPhase>
              #{segment_number_xml(segment_number) if segment_number}
              <ReturnCode>#{return_code}</ReturnCode>
            </mutable>
          </header>
          <body>
            #{data_transfer_xml(phase, order_data) if order_data}
            <ReturnCode authenticate="true">000000</ReturnCode>
          </body>
        </ebicsResponse>
      XML
    end

    def segment_number_xml(segment_number)
      %(<SegmentNumber lastSegment="#{segment_number == segments.size}">#{segment_number}</SegmentNumber>)
    end

    def data_transfer_xml(phase, order_data)
      <<~XML
        <DataTransfer>
          #{data_encryption_info_xml if phase == 'Initialisation'}
          <OrderData>#{Base64.strict_encode64(order_data)}</OrderData>
        </DataTransfer>
      XML
    end

    def data_encryption_info_xml
      <<~XML
        <DataEncryptionInfo authenticate="true">
          <TransactionKey>#{Base64.strict_encode64(client.encryption_key.key.public_encrypt(transaction_key))}</TransactionKey>
        </DataEncryptionInfo>
      XML
    end

    def phase_and_segment_number(request)
      segment_number = request.at_xpath('//e:header/e:mutable/e:SegmentNumber', ns)

      [request.at_xpath('//e:header/e:mutable/e:TransactionPhase', ns).text,
       segment_number&.text,
       segment_number&.[]('lastSegment')]
    end

    let(:zipped_order_data) { File.binread(File.join(File.dirname(__FILE__), 'fixtures', 'test.zip')) }
    let(:transaction_key) { SecureRandom.random_bytes(16) }
    let(:order_data_encrypted) do
      cipher = OpenSSL::Cipher.new('aes-128-cbc').encrypt
      cipher.key = transaction_key

      cipher.update(Zlib::Deflate.deflate(zipped_order_data)) + cipher.final
    end
    let(:missing_bytes) { 0 }
    let(:segment_count) { 3 }
    let(:segments) do
      received = order_data_encrypted.byteslice(0, order_data_encrypted.bytesize - missing_bytes)

      received.bytes.each_slice((received.bytesize / segment_count.to_f).ceil).map { |bytes| bytes.pack('C*') }
    end
    let(:initialisation_response) do
      response('Initialisation', order_data: segments.first, segment_number: 1, num_segments: segments.size)
    end
    let(:requests) { [] }

    subject { client.C53(Date.new(2026, 9, 24), Date.new(2026, 9, 24)) }

    before do
      stub_request(:post, url).to_return do |http_request|
        requests << phase_and_segment_number(Nokogiri::XML(http_request.body))
        phase, segment_number = requests.last
        body = case phase
               when 'Initialisation' then initialisation_response
               when 'Transfer'
                 response('Transfer', order_data: segments[Integer(segment_number) - 1],
                                      segment_number: Integer(segment_number))
               when 'Receipt' then response('Receipt', return_code: '011000')
               end

        { status: 200, body: }
      end
    end

    context 'when the order data arrives short by whole cipher blocks' do
      let(:missing_bytes) { 32 }

      it 'raises without sending the receipt' do
        expect { subject }.to raise_error(Zlib::BufError)
        expect(requests).to eq([['Initialisation', nil, nil], %w[Transfer 2 false], %w[Transfer 3 true]])
      end
    end

    context 'when the order data arrives short by part of a cipher block' do
      let(:missing_bytes) { 5 }

      it 'raises without sending the receipt' do
        expect { subject }.to raise_error(OpenSSL::Cipher::CipherError)
        expect(requests).to eq([['Initialisation', nil, nil], %w[Transfer 2 false], %w[Transfer 3 true]])
      end
    end

    context 'when the response is not segmented' do
      let(:initialisation_response) { response('Initialisation', order_data: order_data_encrypted) }

      it 'returns the order data without sending a receipt' do
        expect(subject).to eq(["ebics is great\n"])
        expect(requests).to eq([['Initialisation', nil, nil]])
      end
    end

    context 'when the order data fits into a single segment' do
      let(:segment_count) { 1 }

      it 'returns the order data and sends the receipt' do
        expect(subject).to eq(["ebics is great\n"])
        expect(requests).to eq([['Initialisation', nil, nil], ['Receipt', nil, nil]])
      end
    end

    versions.each do |version|
      context "when the order data spans several segments (#{version})" do
        let(:version) { version }

        it 'returns the order data of all segments and sends the receipt after the last one' do
          expect(subject).to eq(["ebics is great\n"])
          expect(requests).to eq([['Initialisation', nil, nil],
                                  %w[Transfer 2 false],
                                  %w[Transfer 3 true],
                                  ['Receipt', nil, nil]])
        end
      end
    end
  end
end

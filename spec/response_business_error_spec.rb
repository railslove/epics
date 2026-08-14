RSpec.describe Epics::Response do
  let(:client) do
    Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')),
                      'secret', 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS')
  end

  def response_with(code)
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <ebicsResponse xmlns="urn:org:ebics:H004">
        <body><ReturnCode>#{code}</ReturnCode></body>
      </ebicsResponse>
    XML
    described_class.new(client, xml)
  end

  describe '#business_error?' do
    { '000000' => false,
      '011000' => false,   # positive acknowledgement
      '011301' => false }  # bank does not support prevalidation
      .each do |code, expected|
      it "treats #{code} as #{expected ? 'an error' : 'informational'}" do
        expect(response_with(code).business_error?).to eq(expected)
      end
    end

    # Both are defined as failures in Epics::Error and share the 01 prefix with the
    # informational codes above.
    { '011001' => 'negative acknowledgement received',
      '011101' => 'segment number not reached' }.each do |code, description|
      it "treats #{code} (#{description}) as an error" do
        expect(response_with(code).business_error?).to be(true)
      end
    end

    it 'treats an absent return code as informational' do
      xml = '<?xml version="1.0"?><ebicsResponse xmlns="urn:org:ebics:H004"><body/></ebicsResponse>'
      expect(described_class.new(client, xml).business_error?).to be(false)
    end

    it 'treats an unrelated failure code as an error' do
      expect(response_with('091010').business_error?).to be(true)
    end
  end
end

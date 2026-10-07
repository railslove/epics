class Epics::Response
  # Informational body return codes. Every other 01xxxx code in Epics::Error is a
  # failure -- 011001 is a negative acknowledgement, 011101 a segment underrun.
  BUSINESS_OK_CODES = ['', '000000', '011000', '011301'].freeze

  attr_accessor :doc, :client

  def initialize(client, xml)
    self.doc = Nokogiri::XML.parse(xml)
    self.client = client
  end

  def technical_error?
    !%w[011000 000000].include?(technical_code)
  end

  def technical_code
    mutable_return_code.empty? ? system_return_code : mutable_return_code
  end

  def mutable_return_code
    doc.xpath('//xmlns:header/xmlns:mutable/xmlns:ReturnCode', xmlns: client.urn_schema).text
  end

  def system_return_code
    doc.xpath('//xmlns:SystemReturnCode/xmlns:ReturnCode', xmlns: 'http://www.ebics.org/H000').text
  end

  def business_error?
    !BUSINESS_OK_CODES.include?(business_code)
  end

  def business_code
    doc.xpath('//xmlns:body/xmlns:ReturnCode', xmlns: client.urn_schema).text
  end

  def ok?
    !technical_error? & !business_error?
  end

  def last_segment?
    !!doc.at_xpath("//xmlns:header/xmlns:mutable/*[@lastSegment='true']", xmlns: client.urn_schema)
  end

  def segmented?
    !!doc.at_xpath('//xmlns:header/xmlns:mutable/xmlns:SegmentNumber', xmlns: client.urn_schema)
  end

  def num_segments
    Integer(doc.xpath('//xmlns:header/xmlns:static/xmlns:NumSegments', xmlns: client.urn_schema).text, 10)
  rescue ArgumentError => e
    raise Epics::InvalidResponseError.new('NumSegments', e)
  end

  def return_code
    doc.xpath('//xmlns:ReturnCode', xmlns: client.urn_schema).last.content
  rescue NoMethodError
    nil
  end

  def report_text
    doc.xpath('//xmlns:ReportText', xmlns: client.urn_schema).first.content
  end

  def transaction_id
    doc.xpath('//xmlns:header/xmlns:static/xmlns:TransactionID', xmlns: client.urn_schema).text
  end

  def order_id
    doc.xpath('//xmlns:header/xmlns:mutable/xmlns:OrderID', xmlns: client.urn_schema).text
  end

  def digest_valid?
    authenticated = doc.xpath("//*[@authenticate='true']").map(&:canonicalize).join
    digest_value = doc.xpath('//ds:DigestValue', ds: 'http://www.w3.org/2000/09/xmldsig#').first

    digest = Base64.encode64(OpenSSL::Digest.digest('sha256', authenticated)).strip

    digest == digest_value.content
  end

  def signature_valid?
    key = client.bank_authentication_key
    raise Epics::MissingKeyError, "The bank's authentication key" if !key

    signature = doc.xpath('//ds:SignedInfo', ds: 'http://www.w3.org/2000/09/xmldsig#').first.canonicalize
    signature_value = doc.xpath('//ds:SignatureValue', ds: 'http://www.w3.org/2000/09/xmldsig#').first

    key.verify(signature_value.content, signature)
  end

  def public_digest_valid?
    key = client.encryption_key
    raise Epics::MissingKeyError, 'The encryption key' if !key

    encryption_pub_key_digest = doc.xpath('//xmlns:EncryptionPubKeyDigest', xmlns: client.urn_schema).first

    key.public_digest == encryption_pub_key_digest.content
  end

  def order_data
    decrypt_order_data(order_data_encrypted)
  end

  def order_data_encrypted
    Base64.decode64(doc.xpath('//xmlns:OrderData', xmlns: client.urn_schema).first.content)
  end

  # The bank cuts the segments out of the encrypted order data, so a segment cannot be
  # decrypted on its own: pass the segments of all responses joined. The transaction key
  # only comes with the first response. Raises on truncated order data instead of
  # returning the part that could be read.
  def decrypt_order_data(order_data_encrypted)
    decipher = cipher
    data = decipher.update(order_data_encrypted) + decipher.final

    Zlib::Inflate.inflate(data)
  end

  def cipher
    cipher = OpenSSL::Cipher.new('aes-128-cbc')

    cipher.decrypt
    cipher.padding = 0
    cipher.key = transaction_key
    cipher
  end

  def transaction_key
    transaction_key_encrypted = Base64.decode64(doc.xpath('//xmlns:TransactionKey',
                                                          xmlns: client.urn_schema).first.content)

    @transaction_key ||= client.encryption_key.key.private_decrypt(transaction_key_encrypted)
  end
end

class Epics::Response
  attr_accessor :doc, :client, :raw

  def initialize(client, xml)
    self.raw = xml
    self.doc = Nokogiri::XML.parse(xml)
    self.client = client
  end

  def technical_error?
    !["011000", "000000"].include?(technical_code)
  end

  def technical_code
    doc.xpath("//xmlns:header/xmlns:mutable/xmlns:ReturnCode", xmlns: "urn:org:ebics:H004").text
  end

  def business_error?
    !["", "000000"].include?(business_code)
  end

  def business_code
    doc.xpath("//xmlns:body/xmlns:ReturnCode", xmlns: "urn:org:ebics:H004").text
  end

  def ok?
    !technical_error? & !business_error?
  end

  def last_segment?
    !!doc.at_xpath("//xmlns:header/xmlns:mutable/*[@lastSegment='true']", xmlns: "urn:org:ebics:H004")
  end

  def segmented?
    !!doc.at_xpath("//xmlns:header/xmlns:mutable/xmlns:SegmentNumber", xmlns: "urn:org:ebics:H004")
  end

  def return_code
    doc.xpath("//xmlns:ReturnCode", xmlns: "urn:org:ebics:H004").last.content
  rescue NoMethodError
    nil
  end

  def report_text
    doc.xpath("//xmlns:ReportText", xmlns: "urn:org:ebics:H004").first.content
  end

  def transaction_id
    doc.xpath("//xmlns:header/xmlns:static/xmlns:TransactionID", xmlns: 'urn:org:ebics:H004').text
  end

  def order_id
    doc.xpath("//xmlns:header/xmlns:mutable/xmlns:OrderID", xmlns: "urn:org:ebics:H004").text
  end

  def digest_valid?
    authenticated = doc.xpath("//*[@authenticate='true']").map(&:canonicalize).join
    digest_value = doc.xpath("//ds:DigestValue", ds: "http://www.w3.org/2000/09/xmldsig#").first

    digest = Base64.encode64(digester.digest(authenticated)).strip

    digest == digest_value.content
  end

  def signature_valid?
    signature = doc.xpath("//ds:SignedInfo", ds: "http://www.w3.org/2000/09/xmldsig#").first.canonicalize
    signature_value = doc.xpath("//ds:SignatureValue", ds: "http://www.w3.org/2000/09/xmldsig#").first

    client.bank_x.key.verify(digester, Base64.decode64(signature_value.content), signature)
  end

  def public_digest_valid?
    encryption_pub_key_digest = doc.xpath("//xmlns:EncryptionPubKeyDigest", xmlns: 'urn:org:ebics:H004').first

    client.e.public_digest == encryption_pub_key_digest.content
  end

  def order_data
    order_data_encrypted = Base64.decode64(doc.xpath("//xmlns:OrderData", xmlns: 'urn:org:ebics:H004').first.content)

    data = (cipher.update(order_data_encrypted) + cipher.final)

    Zlib::Inflate.new.inflate(data)
  end

  def cipher
    cipher = OpenSSL::Cipher.new("aes-128-cbc")

    cipher.decrypt
    cipher.padding = 0
    cipher.key = transaction_key
    cipher
  end

  def transaction_key
    transaction_key_encrypted = Base64.decode64(doc.xpath("//xmlns:TransactionKey", xmlns: 'urn:org:ebics:H004').first.content)

    @transaction_key ||= client.e.key.private_decrypt(transaction_key_encrypted)
  end

  def digester
    @digester ||= OpenSSL::Digest::SHA256.new
  end

end

class Epics::Response
  attr_accessor :doc
  attr_accessor :client

  def initialize(client, xml)
    self.doc = Nokogiri::XML.parse(xml)
    self.client = client
  end

  def technical_error?
    !["011000", "000000"].include?(technical_code)
  end

  def technical_code
    doc.xpath("//xmlns:header/xmlns:mutable/xmlns:ReturnCode", xmlns: client.urn_schema).text
  end

  def business_error?
    !["", "000000"].include?(business_code)
  end

  def business_code
    doc.xpath("//xmlns:body/xmlns:ReturnCode", xmlns: client.urn_schema).text
  end

  def ok?
    !technical_error? & !business_error?
  end

  def last_segment?
    !!doc.at_xpath("//xmlns:header/xmlns:mutable/*[@lastSegment='true']", xmlns: client.urn_schema)
  end

  def segmented?
    !!doc.at_xpath("//xmlns:header/xmlns:mutable/xmlns:SegmentNumber", xmlns: client.urn_schema)
  end

  def return_code
    doc.xpath("//xmlns:ReturnCode", xmlns: client.urn_schema).last.content
  rescue NoMethodError
    nil
  end

  def report_text
    doc.xpath("//xmlns:ReportText", xmlns: client.urn_schema).first.content
  end

  def transaction_id
    doc.xpath("//xmlns:header/xmlns:static/xmlns:TransactionID", xmlns: client.urn_schema).text
  end

  def order_id
    doc.xpath("//xmlns:header/xmlns:mutable/xmlns:OrderID", xmlns: client.urn_schema).text
  end

  def digest_valid?
    authenticated = doc.xpath("//*[@authenticate='true']").map(&:canonicalize).join
    digest_value = doc.xpath("//ds:DigestValue", ds: "http://www.w3.org/2000/09/xmldsig#").first

    digest = Base64.encode64(client.signature_key.digester.digest(authenticated)).strip

    digest == digest_value.content
  end

  def signature_valid?
    signature = doc.xpath("//ds:SignedInfo", ds: "http://www.w3.org/2000/09/xmldsig#").first.canonicalize
    signature_value = doc.xpath("//ds:SignatureValue", ds: "http://www.w3.org/2000/09/xmldsig#").first

    client.bank_authentication_key.verify(signature_value.content, signature)
  end

  def public_digest_valid?
    encryption_pub_key_digest = doc.xpath("//xmlns:EncryptionPubKeyDigest", xmlns: client.urn_schema).first

    client.encryption_key.public_digest == encryption_pub_key_digest.content
  end

  def order_data
    order_data_encrypted = Base64.decode64(doc.xpath("//xmlns:OrderData", xmlns: client.urn_schema).first.content)

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
    transaction_key_encrypted = Base64.decode64(doc.xpath("//xmlns:TransactionKey", xmlns: client.urn_schema).first.content)

    @transaction_key ||= client.encryption_key.key.private_decrypt(transaction_key_encrypted)
  end
end

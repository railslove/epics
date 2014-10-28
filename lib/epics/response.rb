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
    doc.xpath("//xmlns:header/xmlns:mutable/xmlns:ReturnCode").text
  end

  def business_error?
    !["", "000000"].include?(business_code)
  end

  def business_code
    doc.xpath("//xmlns:body/xmlns:ReturnCode").text
  end

  def ok?
    !technical_error? & !business_error?
  end

  def last_segment?
    !!doc.at_xpath("//xmlns:header/xmlns:mutable/*[@lastSegment='true']")
  end

  def segmented?
    !!doc.at_xpath("//xmlns:header/xmlns:mutable/xmlns:SegmentNumber")
  end

  def return_code
    doc.xpath("//xmlns:ReturnCode").last.content
  rescue NoMethodError
    nil
  end

  def report_text
    doc.xpath("//xmlns:ReportText").first.content
  end

  def transaction_id
    doc.xpath("//xmlns:header/xmlns:static/xmlns:TransactionID").text
  end

  def digest_valid?
    authenticated = doc.xpath("//*[@authenticate='true']").map(&:canonicalize).join
    digest_value = doc.xpath("//ds:DigestValue").first

    digest = Base64.encode64(digester.digest(authenticated)).strip

    digest == digest_value.content
  end

  def signature_valid?
    signature = doc.xpath("//ds:SignedInfo").first.canonicalize
    signature_value = doc.xpath("//ds:SignatureValue").first

    client.bank_x.key.verify(digester, Base64.decode64(signature_value.content), signature)
  end

  def public_digest_valid?
    encryption_pub_key_digest = doc.xpath("//xmlns:EncryptionPubKeyDigest").first

    client.e.public_digest == encryption_pub_key_digest.content
  end

  def order_data
    order_data_encrypted = Base64.decode64(doc.xpath("//xmlns:OrderData").first.content)

    data = (cipher.update(order_data_encrypted) + cipher.final)

    Zlib::Inflate.new.inflate(data)
  end

  def cipher
    cipher = OpenSSL::Cipher::Cipher.new("aes-128-cbc")

    cipher.decrypt
    cipher.padding = 0
    cipher.key = transaction_key
    cipher
  end

  def transaction_key
    transaction_key_encrypted = Base64.decode64(doc.xpath("//xmlns:TransactionKey").first.content)

    @transaction_key ||= client.e.key.private_decrypt(transaction_key_encrypted)
  end

  def digester
    @digester ||= OpenSSL::Digest::SHA256.new
  end

end

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
    mutable_return_code.empty? ? system_return_code : mutable_return_code
  end

  def mutable_return_code
    doc.xpath("//xmlns:header/xmlns:mutable/xmlns:ReturnCode", xmlns: "urn:org:ebics:H004").text
  end

  def system_return_code
    doc.xpath("//xmlns:SystemReturnCode/xmlns:ReturnCode", xmlns: 'http://www.ebics.org/H000').text
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
  order_data_elements = doc.xpath("//xmlns:OrderData", xmlns: 'urn:org:ebics:H004')
  
  if order_data_elements.empty?
    puts "DEBUG: No OrderData element found in EBICS response" if client.debug_mode
    return nil
  end
  
  order_data_element = order_data_elements.first
  
  if order_data_element.content.nil? || order_data_element.content.empty?
    puts "DEBUG: OrderData element found but content is empty" if client.debug_mode
    return nil
  end
  
  begin
    # For single segment: decode base64 → decrypt → decompress
    order_data_encrypted = Base64.decode64(order_data_element.content)
    
    cipher_obj = cipher
    if cipher_obj.nil?
      puts "DEBUG: Cannot decrypt - cipher is nil (missing transaction key)" if client.debug_mode
      return nil
    end
    
    data = cipher_obj.update(order_data_encrypted) + cipher_obj.final
    Zlib::Inflate.new.inflate(data)
  rescue => e
    puts "DEBUG: Error processing order data: #{e.message}" if client.debug_mode
    nil
  end
end

  def cipher
    cipher = OpenSSL::Cipher.new("aes-128-cbc")

    cipher.decrypt
    cipher.padding = 0
    cipher.key = transaction_key
    cipher
  end

def transaction_key
  # Return cached key if already extracted
  return @transaction_key if defined?(@transaction_key) && @transaction_key
  
  transaction_key_elements = doc.xpath("//xmlns:TransactionKey", xmlns: 'urn:org:ebics:H004')
  
  if transaction_key_elements.empty?
    puts "DEBUG: No TransactionKey element found"
    return nil
  end
  
  transaction_key_element = transaction_key_elements.first
  
  if transaction_key_element.content.nil? || transaction_key_element.content.empty?
    puts "DEBUG: TransactionKey element found but content is empty"
    return nil
  end
  
  begin
    # Convert base64 to binary array
    transaction_key_encrypted = Base64.decode64(transaction_key_element.content)
    puts "DEBUG: TransactionKey encrypted binary size: #{transaction_key_encrypted.bytesize} bytes" if client.debug_mode
    
    # Decrypt with private key
    @transaction_key = client.e.key.private_decrypt(transaction_key_encrypted)
    puts "DEBUG: TransactionKey decrypted size: #{@transaction_key.bytesize} bytes" if client.debug_mode
    @transaction_key
  rescue => e
    puts "DEBUG: Error decrypting transaction key: #{e.message}"
    nil
  end
end

def order_data_binary
  order_data_element = doc.xpath("//xmlns:OrderData", xmlns: 'urn:org:ebics:H004').first
  return nil unless order_data_element
  
  # Just decode base64 to binary, NO decryption
  order_data_binary = Base64.decode64(order_data_element.content)
  return nil if order_data_binary.empty?
  
  puts "DEBUG: Segment binary data: #{order_data_binary.bytesize} bytes" if client.debug_mode
  order_data_binary
end

  def digester
    @digester ||= OpenSSL::Digest::SHA256.new
  end

end

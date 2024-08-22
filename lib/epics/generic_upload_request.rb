class Epics::GenericUploadRequest < Epics::GenericRequest
  attr_accessor :key
  attr_accessor :iv
  attr_accessor :document

  def initialize(client, document, **options)
    super(client, **options)
    self.document = document
    self.key = cipher.random_key
    self.iv = 0.chr * cipher.iv_len
  end

  def cipher
    @cipher ||= OpenSSL::Cipher.new("aes-128-cbc").tap { |cipher| cipher.encrypt }
  end

  def digester
    @digester ||= OpenSSL::Digest::SHA256.new
  end

  def body
    Nokogiri::XML::Builder.new do |xml|
      xml.body {
        xml.DataTransfer {
          xml.DataEncryptionInfo(authenticate: true) {
            xml.EncryptionPubKeyDigest(client.bank_encryption_key.public_digest, Version: client.encryption_version, Algorithm: "http://www.w3.org/2001/04/xmlenc#sha256")
            xml.TransactionKey Base64.encode64(client.bank_encryption_key.key.public_encrypt(self.key)).gsub(/\n/,'')
          }
          xml.SignatureData(encrypted_order_signature, authenticate: true)
        }
      }
    end.doc.root
  end

  def order_signature
    Nokogiri::XML::Builder.new do |xml|
      xml.UserSignatureData('xmlns' => 'http://www.ebics.org/S001', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:schemaLocation' => 'http://www.ebics.org/S001 http://www.ebics.org/S001/ebics_signature.xsd') {
        xml.OrderSignatureData {
          xml.SignatureVersion client.signature_version
          xml.SignatureValue signature_value
          xml.PartnerID partner_id
          xml.UserID user_id
        }
      }
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end

  def signature_value
    client.signature_key.sign( digester.digest(document.gsub(/\n|\r/, "")) )
  end

  def encrypt(d)
    cipher.reset
    cipher.padding = 0
    cipher.key = self.key
    cipher.iv = self.iv
    (cipher.update(pad(d)) + cipher.final)
  end

  def encrypted_order_data
    dst = Zlib::Deflate.deflate(document)

    Base64.encode64(encrypt(dst)).gsub(/\n/,'')
  end

  def encrypted_order_signature
    dst = Zlib::Deflate.deflate(order_signature)

    Base64.encode64(encrypt(dst)).gsub(/\n/,'')
  end

  def pad(d)
    len = cipher.block_size*((d.size / cipher.block_size)+1)

    d.ljust(len, [0].pack("C*")).tap do |padded|
      padded[-1] = [len - d.size].pack("C*")
    end
  end

end

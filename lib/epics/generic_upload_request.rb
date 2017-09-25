class Epics::GenericUploadRequest < Epics::GenericRequest

  attr_accessor :key
  attr_accessor :document

  def initialize(client, document = nil)
    super(client)
    self.document = document
    self.key ||= cipher.random_key
  end

  def segmented?
    true
  end

  def cipher
    @cipher ||= OpenSSL::Cipher.new("aes-128-cbc")
  end

  def digester
    @digester ||= OpenSSL::Digest::SHA256.new
  end

  def body
    {
      "DataTransfer" => {
        "DataEncryptionInfo" => {
          :@authenticate => true,
          "EncryptionPubKeyDigest" => {
            :"@Version" => "E002",
            :"@Algorithm" => "http://www.w3.org/2001/04/xmlenc#sha256",
            :content! => client.bank_e.public_digest
          },
          "TransactionKey" => Base64.encode64(client.bank_e.key.public_encrypt(self.key)).gsub(/\n/,'')
        },
        "SignatureData" => {
          :@authenticate => true,
          :content! => encrypted_order_signature
        }
      }
    }
  end

  def order_signature
    Gyoku.xml("UserSignatureData" => {
      :"@xmlns" => "http://www.ebics.org/S001",
      :"@xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      :"@xsi:schemaLocation" => "http://www.ebics.org/S001 http://www.ebics.org/S001/ebics_signature.xsd",
      "OrderSignatureData" => {
        "SignatureVersion" => "A006",
        "SignatureValue" => signature_value,
        "PartnerID" => partner_id,
        "UserID" => user_id
      }
    })
  end

  def signature_value
    client.a.sign( digester.digest(document.gsub(/\n|\r/, "")) )
  end

  def encrypt(d)
    cipher.reset
    cipher.encrypt
    cipher.padding = 0
    cipher.key = self.key
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

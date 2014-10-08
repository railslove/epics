class Epics::CD1 < Epics::GenericRequest
  attr_accessor :key
  attr_accessor :document
  attr_accessor :transaction_id

  def initialize(client, document)
    super(client)
    self.document = document
    self.key ||= cipher.random_key
  end

  def cipher
    @cipher ||= OpenSSL::Cipher::Cipher.new("aes-128-cbc")
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
    Base64.encode64(client.a.sign( digester.digest(document.gsub(/\n|\r/, "")) )).gsub(/\n/, "")
  end

  def encrypt(d)
    cipher.encrypt
    cipher.padding = 0
    cipher.key = self.key
    (cipher.update(pad(d)) + cipher.final)
  end

  def encrypted_order_data
    z = Zlib::Deflate.new

    dst = z.deflate(document, Zlib::FINISH)
    z.close

    Base64.encode64(encrypt(dst)).gsub(/\n/,'')
  end

  def encrypted_order_signature
    z = Zlib::Deflate.new

    dst = z.deflate(order_signature, Zlib::FINISH)
    z.close

    Base64.encode64(encrypt(dst)).gsub(/\n/,'')
  end

  def pad(d)
    if d.size % 32 == 0
      return d
    else
      len = 32*((d.size / 32)+1)
      padded = d.ljust(len,"01".to_byte_string)
      padded[-1] = "#{len - d.size}".rjust(2, "0").to_byte_string
      padded
    end
  end

  def header
    {
      :@authenticate => true,
      static: {
        "HostID" => host_id,
        "Nonce" => nonce,
        "Timestamp" => timestamp,
        "PartnerID" => partner_id,
        "UserID" => user_id,
        "Product" => {
          :@Language => "de",
          :content! => "EPICS - a ruby ebics kernel"
        },
        "OrderDetails" => {
          "OrderType" => "CD1",
          "OrderAttribute" => "OZHNN",
          "StandardOrderParams/" => ""
        },
        "BankPubKeyDigests" => {
          "Authentication" => {
            :@Version => "X002",
            :@Algorithm => "http://www.w3.org/2001/04/xmlenc#sha256",
            :content! => client.bank_x.public_digest
          },
          "Encryption" => {
            :@Version => "E002",
            :@Algorithm => "http://www.w3.org/2001/04/xmlenc#sha256",
            :content! => client.bank_e.public_digest
          }
        },
        "SecurityMedium" => "0000",
        "NumSegments" => 1
     },
      "mutable" => {
        "TransactionPhase" => "Initialisation"
      }
    }
  end

end

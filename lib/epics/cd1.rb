class Epics::CD1 < Epics::GenericRequest
  attr_accessor :key
  attr_accessor :document
  attr_accessor :transaction_id

  def initialize(client, document)
    super
    self.document = document
    self.key ||= OpenSSL::Cipher::Cipher.new("aes-128-cbc").random_key
  end

  def digester
    OpenSSL::Digest::SHA256.new
  end

  def body
    {
      "DataTransfer" => {
        "DataEncryptionInfo" => {
          :@authenticate => true,
          "EncryptionPubKeyDigest" => {
            :"@Version" => "E002",
            :"@Algorithm" => "http://www.w3.org/2001/04/xmlenc#sha256",
            :content! => client.e.public_digest
          },
          "TransactionKey" => Base64.encode64(client.bank_e.key.public_encrypt(self.key)).gsub(/\n/,'')
        },
        "SignatureData" => {
          :@authenticate => true,
          :content! => Base64.encode64(x(zipped_and_padded_order_signature)).gsub(/\n/,'')
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
        "SignatureValue" => Base64.encode64(client.a.key.sign(digester, document)),
        "PartnerID" => partner_id,
        "UserID" => user_id
      }
    })
  end

  def x(d)
    @c_x ||= OpenSSL::Cipher::Cipher.new("aes-128-cbc")
    @c_x.encrypt
    @c_x.padding = 0
    @c_x.key = self.key
    (@c_x.update(d) + @c_x.final)
  end

  def encrypted_order_data
    z = Zlib::Deflate.new

    dst = z.deflate(document, Zlib::FINISH)
    z.close
    if dst.size % 32 == 0
      padded = dst
    else
      len = 32*((dst.size / 32)+1)
      padded = dst.ljust(len,"01".to_byte_string)
      padded[-1] = "#{len - dst.size}".rjust(2,"0").to_byte_string
    end

    Base64.encode64(x(padded)).gsub(/\n/,'')
  end

  def zipped_and_padded_order_signature
    z = Zlib::Deflate.new

    dst = z.deflate(order_signature, Zlib::FINISH)
    z.close
    if dst.size % 32 == 0
      return dst
    else
      len = 32*((dst.size / 32)+1)
      padded = dst.ljust(len,"01".to_byte_string)
      padded[-1] = "#{len - dst.size}".to_byte_string
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

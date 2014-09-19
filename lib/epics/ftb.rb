class Epics::FTB < Epics::GenericRequest
  attr_accessor :key

  def initialize(client)
    super
    cipher
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
          "TransactionKey" => Base64.encode64(client.bank_e.key.public_encrypt(@key)).strip
        },
        "SignatureData" => {
          :@authenticate => true,
          :content! => Base64.encode64(cipher.update(data) + cipher.final).strip
        }
      }
    }
  end

  def cipher
    @cipher ||= OpenSSL::Cipher::Cipher.new("aes-128-cbc")
    self.key ||= @cipher.random_key
    @cipher.encrypt
    @cipher.padding = 0

    @cipher
  end

  def data
    z = Zlib::Deflate.new
    dst = z.deflate(SecureRandom.hex(96), Zlib::FINISH)
    z.close

    if dst.size % 32 == 0
      return dst
    else
      len = 32*((dst.size / 32)+1)
      dst << "01".to_byte_string
      dst << "01".to_byte_string
      dst << "03".to_byte_string
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
          "OrderType" => "FTB",
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

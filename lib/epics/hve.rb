module Epics
  class HVE < Epics::GenericUploadRequest

    attr_accessor :order_id, :order_type, :digest

    def initialize(client, order_id, order_type, digest)
      super(client)
      self.order_id = order_id
      self.order_type = order_type
      self.digest = digest
    end

    def segmented?
      false
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
            "OrderType" => "HVE",
            "OrderAttribute" => "UZHNN",
            "HVEOrderParams" => {
              "PartnerID" => partner_id,
              "OrderType" => order_type,
              "OrderID" => order_id,
            }
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
          "NumSegments" => 0,
        },
        "mutable" => {
          "TransactionPhase" => "Initialisation"
        }
      }
    end

    def signature_value
      client.a.sign(Base64.strict_decode64(digest))
    end
  end
end

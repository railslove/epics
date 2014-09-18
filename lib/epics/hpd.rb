class Epics::HPD < Epics::GenericRequest

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
          "OrderType" => "HPD",
          "OrderAttribute" => "DZHNN",
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
        "SecurityMedium" => "0000"
     },
      "mutable" => {
        "TransactionPhase" => "Initialisation"
      }
    }
  end
end

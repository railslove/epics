class Epics::VMK < Epics::GenericRequest
  attr_accessor :from, :to

  def initialize(client, from = nil, to = nil)
    super(client)
    self.from = from
    self.to = to
  end

  def date_range
    if !!from && !!to
      { "DateRange" => { "Start" => from, "End" => to } }
    else
      { :content! => '' }
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
          "OrderType" => "VMK",
          "OrderAttribute" => "DZHNN",
          "StandardOrderParams" => date_range
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

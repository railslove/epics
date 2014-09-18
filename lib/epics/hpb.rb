class Epics::HPB < Epics::GenericRequest

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
          "OrderType" => "HPB",
          "OrderAttribute" => "DZHNN"
        },
        "SecurityMedium" => "0000"
      },
      "mutable/" => ""
    }
  end
end

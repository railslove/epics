class Epics::HPB < Epics::GenericRequest
  def root
    "ebicsNoPubKeyDigestsRequest"
  end

  def header
    super do |builder|
      builder.order_type = 'HPB'
      builder.order_attribute = 'DZHNN'
      builder.order_params = nil
      builder.with_bank_pubkey_digests = false
      builder.mutable = ->(xml) {}
    end
  end
end

class Epics::HPB < Epics::GenericRequest
  def root
    "ebicsNoPubKeyDigestsRequest"
  end

  def header
    super do |builder|
      builder.order_type = 'HPB'
      builder.order_attribute = 'DZHNN'
      builder.with_pubkey_digests = false
      builder.mutable = ''
    end
  end
end

class Epics::HPB < Epics::GenericRequest
  def root
    "ebicsNoPubKeyDigestsRequest"
  end

  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'HPB',
      order_attribute: 'DZHNN',
      order_params: false,
      with_bank_pubkey_digests: false,
      mutable: ->(xml) {}
    )
  end
end

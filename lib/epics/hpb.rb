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
      with_bank_pubkey_digests: false,
      mutable: {}
    )
  end
end

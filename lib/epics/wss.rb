class Epics::WSS < Epics::GenericRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'WSS',
      order_attribute: 'DZHNN',
      order_params: {},
      mutable: { TransactionPhase: 'Initialisation' }
    )
  end
end


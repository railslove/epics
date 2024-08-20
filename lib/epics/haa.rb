class Epics::HAA < Epics::GenericRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'HAA',
      order_attribute: 'DZHNN'
    )
  end
end

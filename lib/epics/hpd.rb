class Epics::HPD < Epics::GenericRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'HPD',
      order_attribute: 'DZHNN'
    )
  end
end

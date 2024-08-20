class Epics::HTD < Epics::GenericRequest
  def header
    client.header_builder.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'HTD',
      order_attribute: 'DZHNN'
    )
  end
end

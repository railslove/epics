class Epics::HKD < Epics::GenericRequest
  def header
    client.header_builder.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'HKD',
      order_attribute: 'DZHNN'
    )
  end
end

class Epics::BKA < Epics::GenericRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'BKA',
      order_attribute: 'DZHNN',
      order_params: {
        DateRange: {
          Start: options[:from],
          End: options[:to]
        }
      },
      mutable: { TransactionPhase: 'Initialisation' }
    )
  end
end

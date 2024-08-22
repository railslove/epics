class Epics::C52 < Epics::GenericRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'C52',
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

class Epics::PTK < Epics::GenericRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'PTK',
      order_attribute: 'DZHNN',
      order_params: !!options[:from] && !!options[:to] ? {
        DateRange: {
          Start: options[:from],
          End: options[:to]
        }
      } : {},
      mutable: { TransactionPhase: 'Initialisation' }
    )
  end
end

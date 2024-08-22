class Epics::CCS < Epics::GenericUploadRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'CCS',
      order_attribute: 'DZHNN',
      order_params: {},
      num_segments: 1,
      mutable: { TransactionPhase: 'Initialisation' }
    )
  end
end

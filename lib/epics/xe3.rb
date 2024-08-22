class Epics::XE3 < Epics::GenericUploadRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'XE3',
      order_attribute: 'OZHNN',
      order_params: {},
      num_segments: 1,
      mutable: { TransactionPhase: 'Initialisation' }
    )
  end
end

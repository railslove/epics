class Epics::CCT < Epics::GenericUploadRequest
  def header
    client.header_builder.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'CCT',
      order_attribute: 'OZHNN',
      num_segments: 1
    )
  end
end

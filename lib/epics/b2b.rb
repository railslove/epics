class Epics::B2B < Epics::GenericUploadRequest
  def header
    client.header_builder.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'B2B',
      order_attribute: 'OZHNN',
      num_segments: 1
    )
  end
end

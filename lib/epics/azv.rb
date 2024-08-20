class Epics::AZV < Epics::GenericUploadRequest
  def header
    client.header_builder.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'CD1',
      order_attribute: 'OZHNN',
      num_segments: 1
    )
  end
end

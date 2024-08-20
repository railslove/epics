class Epics::C2S < Epics::GenericUploadRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'C2S',
      order_attribute: 'DZHNN',
      num_segments: 1
    )
  end
end

class Epics::XCT < Epics::GenericUploadRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'XCT',
      order_attribute: 'OZHNN',
      num_segments: 1
    )
  end
end

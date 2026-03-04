class Epics::XCT < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_azv(document_digest, transaction_key)
    builder.to_xml
  end
end

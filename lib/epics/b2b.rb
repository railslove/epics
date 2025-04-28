class Epics::B2B < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_b2b(document_digest, transaction_key)
    builder.to_xml
  end
end

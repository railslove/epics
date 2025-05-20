class Epics::CCT < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_cct(document_digest, transaction_key)
    builder.to_xml
  end
end

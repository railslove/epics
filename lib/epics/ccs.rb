class Epics::CCS < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_ccs(document_digest, transaction_key)
    builder.to_xml
  end
end

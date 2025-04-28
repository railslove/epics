class Epics::CDB < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_cdb(document_digest, transaction_key)
    builder.to_xml
  end
end

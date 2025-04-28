class Epics::CD1 < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_cd1(document_digest, transaction_key)
    builder.to_xml
  end
end

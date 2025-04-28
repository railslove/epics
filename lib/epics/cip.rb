class Epics::CIP < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_cip(document_digest, transaction_key)
    builder.to_xml
  end
end

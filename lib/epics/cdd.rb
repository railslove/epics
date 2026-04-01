class Epics::CDD < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_cdd(document_digest, transaction_key, **options)
    builder.to_xml
  end
end

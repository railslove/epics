class Epics::YCT < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_yct(document_digest, transaction_key, **options)
    builder.to_xml
  end
end

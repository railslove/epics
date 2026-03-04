class Epics::FUL < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_ful(document_digest, transaction_key, file_format: options[:file_format])
    builder.to_xml
  end
end

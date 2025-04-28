class Epics::C2S < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_c2s(document_digest, transaction_key)
    builder.to_xml
  end
end

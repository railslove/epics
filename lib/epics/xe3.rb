class Epics::XE3 < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_xe3(document_digest, transaction_key)
    builder.to_xml
  end
end

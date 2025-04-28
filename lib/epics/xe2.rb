class Epics::XE2 < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_xe2(document_digest, transaction_key)
    builder.to_xml
  end
end

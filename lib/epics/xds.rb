class Epics::XDS < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_xds(document_digest, transaction_key)
    builder.to_xml
  end
end

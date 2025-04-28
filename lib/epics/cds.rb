class Epics::CDS < Epics::GenericUploadRequest
  def to_xml
    builder = request_factory.create_cds(document_digest, transaction_key)
    builder.to_xml
  end
end

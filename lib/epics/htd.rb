class Epics::HTD < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_htd
    builder.to_xml
  end
end

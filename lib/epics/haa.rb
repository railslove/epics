class Epics::HAA < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_haa
    builder.to_xml
  end
end

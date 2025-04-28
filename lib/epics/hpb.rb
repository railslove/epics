class Epics::HPB < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_hpb
    builder.to_xml
  end
end

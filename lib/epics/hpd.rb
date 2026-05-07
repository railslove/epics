class Epics::HPD < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_hpd
    builder.to_xml
  end
end

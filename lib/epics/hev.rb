class Epics::HEV < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_hev
    builder.to_xml
  end
end

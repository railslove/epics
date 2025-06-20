class Epics::WSS < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_wss
    builder.to_xml
  end
end


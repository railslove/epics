class Epics::HVU < Epics::GenericRequest
  def to_xml
    request_factory.create_hvu.to_xml
  end
end

class Epics::HKD < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_hkd
    builder.to_xml
  end
end

class Epics::Z53 < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_z53(options[:from], options[:to])
    builder.to_xml
  end
end

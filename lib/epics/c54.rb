class Epics::C54 < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_c54(options[:from], options[:to])
    builder.to_xml
  end
end

class Epics::C52 < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_c52(options[:from], options[:to])
    builder.to_xml
  end
end

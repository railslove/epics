class Epics::C53 < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_c53(options[:from], options[:to])
    builder.to_xml
  end
end

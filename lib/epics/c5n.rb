class Epics::C5N < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_c5n(options[:from], options[:to])
    builder.to_xml
  end
end

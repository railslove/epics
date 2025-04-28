class Epics::STA < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_sta(options[:from], options[:to])
    builder.to_xml
  end
end

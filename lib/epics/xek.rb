class Epics::XEK < Epics::GenericRequest
  def to_xml
    request_factory.create_xek(options[:from], options[:to], **service_options).to_xml
  end
end

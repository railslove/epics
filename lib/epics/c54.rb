class Epics::C54 < Epics::GenericRequest
  def to_xml
    request_factory.create_c54(options[:from], options[:to], **service_options).to_xml
  end
end

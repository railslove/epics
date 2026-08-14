class Epics::C52 < Epics::GenericRequest
  def to_xml
    request_factory.create_c52(options[:from], options[:to], **service_options).to_xml
  end
end

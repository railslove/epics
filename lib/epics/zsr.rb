class Epics::ZSR < Epics::GenericRequest
  def to_xml
    request_factory.create_zsr(options[:from], options[:to], **service_options).to_xml
  end
end

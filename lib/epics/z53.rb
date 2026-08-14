class Epics::Z53 < Epics::GenericRequest
  def to_xml
    request_factory.create_z53(options[:from], options[:to], **service_options).to_xml
  end
end

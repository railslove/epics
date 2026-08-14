class Epics::Z54 < Epics::GenericRequest
  def to_xml
    request_factory.create_z54(options[:from], options[:to], **service_options).to_xml
  end
end

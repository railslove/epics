class Epics::Z52 < Epics::GenericRequest
  def to_xml
    request_factory.create_z52(options[:from], options[:to], **service_options).to_xml
  end
end

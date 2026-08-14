class Epics::Z01 < Epics::GenericRequest
  def to_xml
    request_factory.create_z01(options[:from], options[:to], **service_options).to_xml
  end
end

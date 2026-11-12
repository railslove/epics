class Epics::VPZ < Epics::GenericRequest
  def to_xml
    request_factory.create_vpz(options[:from], options[:to]).to_xml
  end
end

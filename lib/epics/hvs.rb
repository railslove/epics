class Epics::HVS < Epics::GenericRequest
  def to_xml
    request_factory.create_hvs(options[:order_id], options[:service], options[:digest]).to_xml
  end
end

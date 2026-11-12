class Epics::HVE < Epics::GenericRequest
  def to_xml
    request_factory.create_hve(options[:order_id], options[:service], options[:digest]).to_xml
  end
end

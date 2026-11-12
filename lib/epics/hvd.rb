class Epics::HVD < Epics::GenericRequest
  def to_xml
    request_factory.create_hvd(options[:order_id], options[:service]).to_xml
  end
end

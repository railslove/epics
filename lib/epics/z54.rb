class Epics::Z54 < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_z54(options[:from], options[:to])
    builder.to_xml
  end
end

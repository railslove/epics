class Epics::CDZ < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_cdz(options[:from], options[:to])
    builder.to_xml
  end
end

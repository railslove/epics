class Epics::Z01 < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_z01(options[:from], options[:to])
    builder.to_xml
  end
end

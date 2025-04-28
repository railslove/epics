class Epics::PTK < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_ptk(options[:from], options[:to])
    builder.to_xml
  end
end

class Epics::CRZ < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_crz(options[:from], options[:to])
    builder.to_xml
  end
end

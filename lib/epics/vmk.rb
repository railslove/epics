class Epics::VMK < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_vmk(options[:from], options[:to])
    builder.to_xml
  end
end

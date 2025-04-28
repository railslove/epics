class Epics::BKA < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_bka(options[:from], options[:to])
    builder.to_xml
  end
end

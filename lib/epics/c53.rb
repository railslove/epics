class Epics::C53 < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_c53(
      options[:from],
      options[:to],
      scope: options[:scope],
      msg_name_version: options[:msg_name_version]
    )
    builder.to_xml
  end
end

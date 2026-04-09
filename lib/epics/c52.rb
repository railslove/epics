class Epics::C52 < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_c52(
      options[:from],
      options[:to],
      scope: options[:scope],
      msg_name_version: options[:msg_name_version],
      container_type: options[:container_type]
    )
    builder.to_xml
  end
end

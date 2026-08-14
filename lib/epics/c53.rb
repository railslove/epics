class Epics::C53 < Epics::GenericRequest
  def to_xml
    # Compacted so unset options fall through to the factory defaults.
    params = {
      scope: options[:scope],
      msg_name_version: options[:msg_name_version],
      container_type: options[:container_type],
    }.compact

    request_factory.create_c53(options[:from], options[:to], **params).to_xml
  end
end

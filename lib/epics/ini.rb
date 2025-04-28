class Epics::INI < Epics::GenericRequest
  def key_signature
    order_data = order_data_handle.handle_ini(client.keyring.user_signature)
    order_data.to_xml
  end

  def to_xml
    builder = request_factory.create_ini(key_signature)
    builder.to_xml
  end
end

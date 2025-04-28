class Epics::HIA < Epics::GenericRequest
  def order_data
    order_data = order_data_handle.handle_hia(client.keyring.user_authentication, client.keyring.user_encryption)
    order_data.to_xml
  end

  def to_xml
    builder = request_factory.create_hia(order_data)
    builder.to_xml
  end
end

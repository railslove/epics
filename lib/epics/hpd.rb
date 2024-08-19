class Epics::HPD < Epics::GenericRequest
  def header
    super do |builder|
      builder.order_type = 'HPD'
      builder.order_attribute = 'DZHNN'
      builder.order_params = ''
    end
  end
end

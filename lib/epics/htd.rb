class Epics::HTD < Epics::GenericRequest
  def header
    super do |builder|
      builder.order_type = 'HTD'
      builder.order_attribute = 'DZHNN'
      builder.order_params = ''
    end
  end
end

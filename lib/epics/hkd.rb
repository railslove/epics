class Epics::HKD < Epics::GenericRequest
  def header
    super do |builder|
      builder.order_type = 'HKD'
      builder.order_attribute = 'DZHNN'
      builder.order_params = ''
    end
  end
end

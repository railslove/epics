class Epics::HAA < Epics::GenericRequest
  def header
    super do |builder|
      builder.order_type = 'HAA'
      builder.order_attribute = 'DZHNN'
      builder.order_params = ''
    end
  end
end

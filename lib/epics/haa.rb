class Epics::HAA < Epics::GenericRequest
  def header
    super do |builder|
      builder.order_type = 'HAA'
      builder.order_attribute = 'DZHNN'
    end
  end
end

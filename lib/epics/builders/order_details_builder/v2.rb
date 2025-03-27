class Epics::Builders::OrderDetailsBuilder::V2 < Epics::Builders::OrderDetailsBuilder::Base
  def add_order_type(order_type)
    @xml.OrderType order_type
  end

  def add_order_attribute(order_attribute)
    @xml.OrderAttribute order_attribute
  end
end

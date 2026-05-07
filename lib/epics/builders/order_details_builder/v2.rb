class Epics::Builders::OrderDetailsBuilder::V2 < Epics::Builders::OrderDetailsBuilder::Base
  def add_order_type(order_type)
    @xml.OrderType order_type
  end

  def add_admin_order_type(order_type)
    raise Epics::VersionSupportError, 3.0
  end

  def add_order_attribute(order_attribute)
    @xml.OrderAttribute order_attribute
  end

  def add_btd_order_params
    raise Epics::VersionSupportError, 3.0
  end

  def add_btu_order_params
    raise Epics::VersionSupportError, 3.0
  end
end

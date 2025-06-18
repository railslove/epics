class Epics::Builders::OrderDetailsBuilder::V3 < Epics::Builders::OrderDetailsBuilder::Base
  def add_order_type(order_type)
    raise Epics::VersionSupportError, 2.5, 'below'
  end

  def add_admin_order_type(order_type)
    @xml.AdminOrderType order_type
  end

  def add_order_attribute(order_attribute)
    raise Epics::VersionSupportError, 2.5, 'below'
  end

  def add_btd_order_params(
    service_name:, scope: nil, service_option: nil,
    container_flag: nil, container_type: nil, start_date: nil, end_date: nil,
    msg_name:, msg_name_version: nil, msg_name_variant: nil, msg_name_format: nil
  )
    @xml.BTDOrderParams do |xml|
      xml.Service do
        xml.ServiceName service_name
        xml.Scope scope if scope
        xml.ServiceOption service_option if service_option
        xml.ContainerFlag container_flag if container_flag
        xml.Container '', containerType: container_type if container_type
        msg_name_attributes = {}
        msg_name_attributes[:version] = msg_name_version if msg_name_version
        msg_name_attributes[:variant] = msg_name_variant if msg_name_variant
        msg_name_attributes[:format] = msg_name_format if msg_name_format
        xml.MsgName msg_name, msg_name_attributes
      end
      xml.parent.add_child(create_date_range(start_date, end_date)) if start_date && end_date
    end
  end

  def add_btu_order_params(
    filename:, service_name:, scope: nil, service_option: nil, container_flag: nil,
    msg_name:, msg_name_version: nil, msg_name_variant: nil, msg_name_format: nil
  )
    @xml.BTUOrderParams fileName: filename do |xml|
      xml.Service do
        xml.ServiceName service_name
        xml.Scope scope if scope
        xml.ServiceOption service_option if service_option
        xml.ContainerFlag container_flag if container_flag
        msg_name_attributes = {}
        msg_name_attributes[:version] = msg_name_version if msg_name_version
        msg_name_attributes[:variant] = msg_name_variant if msg_name_variant
        msg_name_attributes[:format] = msg_name_format if msg_name_format
        xml.MsgName msg_name, msg_name_attributes
      end
    end
  end
end

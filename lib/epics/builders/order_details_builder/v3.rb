class Epics::Builders::OrderDetailsBuilder::V3 < Epics::Builders::OrderDetailsBuilder::Base
  def add_order_type(_order_type)
    raise Epics::VersionSupportError.new(3.0, 'below')
  end

  def add_admin_order_type(order_type)
    @xml.AdminOrderType order_type
  end

  def add_order_attribute(_order_attribute)
    raise Epics::VersionSupportError.new(3.0, 'below')
  end

  def add_btd_order_params(
    service_name:, msg_name:, scope: nil, service_option: nil,
    container_type: nil, start_date: nil, end_date: nil, msg_name_version: nil, msg_name_variant: nil, msg_name_format: nil
  )
    @xml.BTDOrderParams do |xml|
      xml.Service do
        xml.ServiceName service_name
        xml.Scope scope if scope
        xml.ServiceOption service_option if service_option
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
    filename:,
    service_name:,
    msg_name:,
    scope: nil,
    service_option: nil,
    container_type: nil,
    msg_name_version: nil,
    msg_name_variant: nil,
    msg_name_format: nil,
    signature_flag: true,
    request_eds: false
  )
    if request_eds && !signature_flag
      raise ArgumentError, 'request_eds requires signature_flag'
    end

    @xml.BTUOrderParams fileName: filename do |xml|
      xml.Service do
        xml.ServiceName service_name
        xml.Scope scope if scope
        xml.ServiceOption service_option if service_option
        xml.Container '', containerType: container_type if container_type
        msg_name_attributes = {}
        msg_name_attributes[:version] = msg_name_version if msg_name_version
        msg_name_attributes[:variant] = msg_name_variant if msg_name_variant
        msg_name_attributes[:format] = msg_name_format if msg_name_format
        xml.MsgName msg_name, msg_name_attributes
      end
      # Without SignatureFlag the bank treats the order as carrying no ES (electronic
      # signature) and expects authorisation outside EBICS. requestEDS asks the bank to
      # spool the order into the EDS (distributed electronic signature, German VEU,
      # "Verteilte Elektronische Unterschrift") instead of rejecting it when signatures
      # are still missing.
      if signature_flag
        signature_flag_attributes = {}
        signature_flag_attributes[:requestEDS] = 'true' if request_eds
        xml.SignatureFlag '', signature_flag_attributes
      end
    end
  end

  protected

  def add_order_identification(xml, service)
    service_name, msg_name, scope, service_option, container_type =
      service.values_at(:service_name, :msg_name, :scope, :service_option, :container_type)

    xml.Service do
      xml.ServiceName service_name
      xml.Scope scope if scope
      xml.ServiceOption service_option if service_option
      xml.Container '', containerType: container_type if container_type
      xml.MsgName msg_name
    end
  end
end

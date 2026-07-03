# frozen_string_literal: true

# Value object describing an EBICS 3.0 (H005) Business Transaction Format (BTF).
#
# A BTF replaces the H004 OrderType/FileFormat combination. It is expressed via
# the <Service> element inside BTU/BTD order params:
#
#   <Service>
#     <ServiceName>SCT</ServiceName>
#     <ServiceOption>...</ServiceOption>   (optional)
#     <Scope>DE</Scope>                     (optional)
#     <Container containerType="ZIP"/>      (optional)
#     <MsgName version="03">pain.001</MsgName>
#   </Service>
#
# Example:
#
#   Epics::BTF.new(
#     service_name: "SCT",
#     scope: "DE",
#     msg_name: "pain.001",
#     msg_version: "03",
#   )
#
# A plain Hash with the same keys is accepted anywhere a BTF is expected.
class Epics::BTF
  attr_reader :service_name, :service_option, :scope, :container,
              :msg_name, :msg_version, :msg_variant, :msg_format

  def initialize(service_name:, msg_name:, scope: nil, service_option: nil,
                 container: nil, msg_version: nil, msg_variant: nil, msg_format: nil)
    @service_name   = service_name
    @service_option = service_option
    @scope          = scope
    @container      = container
    @msg_name       = msg_name
    @msg_version    = msg_version
    @msg_variant    = msg_variant
    @msg_format     = msg_format
  end

  # Normalized hash consumed by Epics::HeaderRequest#build_service.
  def to_h
    {
      service_name: service_name,
      service_option: service_option,
      scope: scope,
      container: container,
      msg_name: {
        name: msg_name,
        version: msg_version,
        variant: msg_variant,
        format: msg_format,
      },
    }
  end
end

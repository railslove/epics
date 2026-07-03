# frozen_string_literal: true

# EBICS 3.0 (H005) generic download order. Replaces the H004 FDL order: instead
# of a FileFormat string the transfer is described by a BTF <Service>.
#
#   client.BTD(Epics::BTF.new(service_name: "EOP", scope: "DE", msg_name: "camt.053", msg_version: "08"), from: "2026-01-01", to: "2026-01-31")
class Epics::BTD < Epics::GenericRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      admin_order_type: 'BTD',
      service: options[:service],
      from: options[:from],
      to: options[:to],
      parameters: options[:parameters],
      mutable: { TransactionPhase: 'Initialisation' }
    )
  end
end

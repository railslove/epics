# frozen_string_literal: true

# EBICS 3.0 (H005) generic upload order. Replaces the H004 FUL order: instead of
# a FileFormat string the transfer is described by a BTF <Service>.
#
#   client.BTU(document, Epics::BTF.new(service_name: "SCT", scope: "DE", msg_name: "pain.001", msg_version: "03"))
class Epics::BTU < Epics::GenericUploadRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      admin_order_type: 'BTU',
      service: options[:service],
      signature_flag: options.fetch(:signature_flag, true),
      request_eds: options[:request_eds],
      parameters: options[:parameters],
      mutable: { TransactionPhase: 'Initialisation' }
    )
  end
end

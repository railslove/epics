# frozen_string_literal: true

class Epics::FDL < Epics::GenericRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'FDL',
      order_attribute: 'DZHNN',
      order_id: 'A00A',
      custom_order_params: { FDLOrderParams: { FileFormat: options[:file_format] } },
      mutable: { TransactionPhase: 'Initialisation' }
    )
  end
end

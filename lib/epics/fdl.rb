# frozen_string_literal: true

class Epics::FDL < Epics::GenericRequest
  def header
    fdl_order_params = Hash.new.tap do |params|
      params[:DateRange] = {
        Start: options[:from],
        End: options[:to],
      } if options[:from] && options[:to]
      params[:FileFormat] = options[:file_format]
    end

    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'FDL',
      order_attribute: 'DZHNN',
      order_id: 'A00A',
      custom_order_params: { FDLOrderParams: fdl_order_params },
      mutable: { TransactionPhase: 'Initialisation' }
    )
  end
end

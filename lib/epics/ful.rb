# frozen_string_literal: true

class Epics::FUL < Epics::GenericUploadRequest
  def header
    ful_order_params = Hash.new.tap do |params|
      params[:FileFormat] = options[:file_format]
    end

    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'FUL',
      order_attribute: 'DZHNN',
      custom_order_params: { FULOrderParams: ful_order_params },
      mutable: { TransactionPhase: 'Initialisation' }
    )
  end
end

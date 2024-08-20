class Epics::STA < Epics::GenericRequest
  def header
    client.header_builder.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'STA',
      order_attribute: 'DZHNN',
      order_params: ->(xml) {
        xml.DateRange {
          xml.Start options[:from]
          xml.End options[:to]
        } if !!options[:from] && !!options[:to]
      }
    )
  end
end

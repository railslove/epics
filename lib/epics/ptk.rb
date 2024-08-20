class Epics::PTK < Epics::GenericRequest
  def header
    if !!options[:from] && !!options[:to]
      client.header_builder.build(
        nonce: nonce,
        timestamp: timestamp,
        order_type: 'PTK',
        order_attribute: 'DZHNN',
        order_params: ->(xml) {
          xml.DateRange {
            xml.Start options[:from]
            xml.End options[:to]
          }
        }
      )
    else
      client.header_builder.build(
        nonce: nonce,
        timestamp: timestamp,
        order_type: 'PTK',
        order_attribute: 'DZHNN',
      )
    end
  end
end

class Epics::C54 < Epics::GenericRequest
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'C54',
      order_attribute: 'DZHNN',
      order_params: ->(xml) {
        xml.DateRange {
          xml.Start options[:from]
          xml.End options[:to]
        }
      }
    )
  end
end

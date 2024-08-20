class Epics::HAC < Epics::GenericRequest
  # By default HAC only returns data for transactions which have not yet been fetched. Therefore,
  # most applications not not have to specify a date range, but can simply fetch the status and
  # be done
  def header
    client.header_request.build(
      nonce: nonce,
      timestamp: timestamp,
      order_type: 'HAC',
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

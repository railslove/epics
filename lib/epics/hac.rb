class Epics::HAC < Epics::GenericRequest
  # By default HAC only returns data for transactions which have not yet been fetched. Therefore,
  # most applications not not have to specify a date range, but can simply fetch the status and
  # be done
  def header
    super do |builder|
      builder.order_type = 'HAC'
      builder.order_attribute = 'DZHNN'

      if !!options[:from] && !!options[:to]
        builder.order_params = ->(xml) {
          xml.DateRange {
            xml.Start options[:from]
            xml.End options[:to]
          }
        }
      else
        builder.order_params = ''
      end
    end
  end
end

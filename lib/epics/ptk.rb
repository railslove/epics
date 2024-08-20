class Epics::PTK < Epics::GenericRequest
  def header
    super do |builder|
      builder.order_type = 'PTK'
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

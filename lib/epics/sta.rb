class Epics::STA < Epics::GenericRequest
  def header
    super do |builder|
      builder.order_type = 'STA'
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

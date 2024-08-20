class Epics::VMK < Epics::GenericRequest
  def header
    super do |builder|
      builder.order_type = 'VMK'
      builder.order_attribute = 'DZHNN'

      if !!options[:from] && !!options[:to]
        builder.order_params = ->(xml) {
          xml.DateRange {
            xml.Start options[:from]
            xml.End options[:to]
          }
        }
      end
    end
  end
end

class Epics::C53 < Epics::GenericRequest
  def header
    super do |builder|
      builder.order_type = 'C53'
      builder.order_attribute = 'DZHNN'
      builder.order_params = ->(xml) {
        xml.DateRange {
          xml.Start options[:from]
          xml.End options[:to]
        }
      }
    end
  end
end

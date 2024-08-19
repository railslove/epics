class Epics::C52 < Epics::GenericRequest
  attr_accessor :from, :to

  def initialize(client, from, to)
    super(client)
    self.from = from
    self.to = to
  end

  def header
    super do |builder|
      builder.order_type = 'C52'
      builder.order_attribute = 'DZHNN'
      builder.order_params = ->(xml) {
        xml.DateRange {
          xml.Start from
          xml.End to
        }
      }
    end
  end
end

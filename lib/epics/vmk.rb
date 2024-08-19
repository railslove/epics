class Epics::VMK < Epics::GenericRequest
  attr_accessor :from, :to

  def initialize(client, from = nil, to = nil)
    super(client)
    self.from = from
    self.to = to
  end

  def header
    super do |builder|
      builder.order_type = 'VMK'
      builder.order_attribute = 'DZHNN'

      if !!from && !!to
        builder.order_params = ->(xml) {
          xml.DateRange {
            xml.Start from
            xml.End to
          }
        }
      else
        builder.order_params = ''
      end
    end
  end
end

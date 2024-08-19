class Epics::HAC < Epics::GenericRequest
  attr_accessor :from, :to

  # By default HAC only returns data for transactions which have not yet been fetched. Therefore,
  # most applications not not have to specify a date range, but can simply fetch the status and
  # be done
  def initialize(client, from = nil, to = nil)
    super(client)
    self.from = from
    self.to = to
  end

  def header
    super do |builder|
      builder.order_type = 'HAC'
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

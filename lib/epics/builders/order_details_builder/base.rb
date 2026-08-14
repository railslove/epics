class Epics::Builders::OrderDetailsBuilder::Base
  def initialize
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      xml.OrderDetails do
        yield self
      end
    end
  end

  def add_order_type
    raise NotImplementedError
  end

  def add_admin_order_type
    raise NotImplementedError
  end

  def add_order_id(order_id)
    @xml.OrderID order_id.to_s(36).upcase.rjust(4, '0')
    self
  end

  def add_order_attribute(order_attribute)
    raise NotImplementedError
  end

  def add_standard_order_params(start_date = nil, end_date = nil)
    date_range = create_date_range(start_date, end_date)
    @xml.StandardOrderParams do |xml|
      xml.parent.add_child(date_range) if date_range
    end
    self
  end

  def add_fdl_order_params(format, start_date = nil, end_date = nil)
    date_range = create_date_range(start_date, end_date)
    @xml.FDLOrderParams do |xml|
      xml.parent.add_child(date_range) if date_range
      xml.FileFormat format
    end
    self
  end

  def add_ful_order_params(format)
    @xml.FULOrderParams do |xml|
      xml.FileFormat format
    end
    self
  end

  def add_btd_order_params
    raise NotImplementedError
  end

  def add_btu_order_params
    raise NotImplementedError
  end

  def doc
    @xml.doc.root
  end

  protected

  # Start and End are both mandatory within DateRange: no bounds means no range, one
  # bound cannot be rendered at all.
  def create_date_range(start_date, end_date)
    return if start_date.nil? && end_date.nil?

    if start_date.nil? || end_date.nil?
      raise ArgumentError, 'DateRange requires both a start and an end date, got ' \
                           "start_date=#{start_date.inspect} end_date=#{end_date.inspect}"
    end

    start_date = coerce_date(start_date, 'start_date')
    end_date = coerce_date(end_date, 'end_date')

    Nokogiri::XML::Builder.new do |xml|
      xml.DateRange do
        xml.Start start_date.iso8601
        xml.End end_date.iso8601
      end
    end.doc.root
  end

  # Start and End are xs:date; Time and DateTime would render an xs:dateTime with an
  # offset and be rejected.
  def coerce_date(value, name)
    case value
    when String
      puts "DEPRECATION WARNING: #{name} is a String, use Date instead"
      Date.parse(value)
    when DateTime, Time
      value.to_date
    else
      value
    end
  end
end

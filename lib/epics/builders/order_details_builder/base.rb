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
    @xml.StandardOrderParams do |xml|
      xml.parent.add_child(create_date_range(start_date, end_date)) if start_date && end_date
    end
    self
  end

  def add_fdl_order_params(format, start_date = nil, end_date = nil)
    @xml.FDLOrderParams do |xml|
      xml.parent.add_child(create_date_range(start_date, end_date)) if start_date && end_date
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

  def create_date_range(start_date, end_date)
    if start_date.is_a?(String)
      start_date = Date.parse(start_date)
      puts "DEPRECATION WARNING: start_date is a String, use Date instead"
    end
    if end_date.is_a?(String)
      end_date = Date.parse(end_date)
      puts "DEPRECATION WARNING: end_date is a String, use Date instead"
    end

    Nokogiri::XML::Builder.new do |xml|
      xml.DateRange do
        xml.Start start_date.iso8601
        xml.End end_date.iso8601
      end
    end.doc.root
  end
end

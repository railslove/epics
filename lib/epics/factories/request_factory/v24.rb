class Epics::Factories::RequestFactory::V24 < Epics::Factories::RequestFactory::V2
  NOT_IMPLEMENTED_ORDER_TYPES = %w[
    xek yct zsr
  ].freeze

  NOT_IMPLEMENTED_ORDER_TYPES.each do |type|
    define_method("create_#{type}") { |*| raise NotImplementedError }
  end

  protected

  def xml_builder
    Epics::Builders::XmlBuilder::V24.new
  end

  def add_order_type(order_details_builder, order_type, with_es = false)
    order_attribute = case order_type
    when 'INI', 'HIA'
      Epics::Builders::OrderDetailsBuilder::ORDER_ATTRIBUTE_DZNNN
    else
      if with_es
        Epics::Builders::OrderDetailsBuilder::ORDER_ATTRIBUTE_OZHNN
      else
        Epics::Builders::OrderDetailsBuilder::ORDER_ATTRIBUTE_DZHNN
      end
    end

    order_details_builder.add_order_type order_type
    order_details_builder.add_order_id @client.next_order_id
    order_details_builder.add_order_attribute order_attribute
  end
end

class Epics::Builders::StaticBuilder::V3 < Epics::Builders::StaticBuilder::Base
  def add_order_details
    instance = Epics::Builders::OrderDetailsBuilder::V3.new do |instance|
      yield instance
    end
    @xml.parent.add_child(instance.doc)
    self
  end
end

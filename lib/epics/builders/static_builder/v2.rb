class Epics::Builders::StaticBuilder::V2 < Epics::Builders::StaticBuilder::Base
  def add_order_details
    instance = Epics::Builders::OrderDetailsBuilder::V2.new do |instance|
      yield instance
    end
    @xml.parent.add_child(instance.doc)
    self
  end
end

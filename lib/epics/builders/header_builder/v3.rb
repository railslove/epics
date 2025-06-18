class Epics::Builders::HeaderBuilder::V3 < Epics::Builders::HeaderBuilder::Base
  def add_static
    instance = Epics::Builders::StaticBuilder::V3.new do |instance|
      yield instance
    end
    @xml.parent.add_child(instance.doc)
    self
  end
end

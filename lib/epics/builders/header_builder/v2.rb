class Epics::Builders::HeaderBuilder::V2 < Epics::Builders::HeaderBuilder::Base
  def add_static
    instance = Epics::Builders::StaticBuilder::V2.new do |instance|
      yield instance
    end
    @xml.parent.add_child(instance.doc)
    self
  end
end

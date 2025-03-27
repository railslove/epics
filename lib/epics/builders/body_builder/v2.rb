class Epics::Builders::BodyBuilder::V2 < Epics::Builders::BodyBuilder::Base
  def add_data_transfer
    instance = Epics::Builders::DataTransferBuilder::V2.new do |instance|
      yield instance
    end
    @xml.parent.add_child(instance.doc)
    self
  end
end

class Epics::Builders::XmlBuilder::V25 < Epics::Builders::XmlBuilder::Base
  def add_header
    instance = Epics::Builders::HeaderBuilder::V2.new do |instance|
      yield instance
    end
    @xml.parent.add_child(instance.doc)
    self
  end

  def add_body
    instance = Epics::Builders::BodyBuilder::V2.new do |instance|
      yield instance if block_given?
    end
    @xml.parent.add_child(instance.doc)
    self
  end

  protected

  def h00x_version
    'H004'
  end

  def h00x_namespace
    'urn:org:ebics:H004'
  end
end

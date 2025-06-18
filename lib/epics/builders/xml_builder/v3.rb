class Epics::Builders::XmlBuilder::V3 < Epics::Builders::XmlBuilder::Base
  def add_header
    instance = Epics::Builders::HeaderBuilder::V3.new do |instance|
      yield instance
    end
    @xml.parent.add_child(instance.doc)
    self
  end

  def add_body
    instance = Epics::Builders::BodyBuilder::V3.new do |instance|
      yield instance if block_given?
    end
    @xml.parent.add_child(instance.doc)
    self
  end

  protected

  def h00x_version
    'H005'
  end

  def h00x_namespace
    'urn:org:ebics:H005'
  end
end

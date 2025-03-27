class Epics::Builders::HeaderBuilder::Base
  def initialize
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      xml.header(authenticate: true) do
        yield self
      end
    end
  end

  def add_static
    raise NotImplementedError
  end

  def add_mutable
    instance = Epics::Builders::MutableBuilder.new do |instance|
      yield instance if block_given?
    end
    @xml.parent.add_child(instance.doc)
    self
  end

  def doc
    @xml.doc.root
  end
end

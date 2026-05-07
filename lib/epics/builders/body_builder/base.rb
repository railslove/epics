class Epics::Builders::BodyBuilder::Base
  def initialize
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      xml.body do
        yield self
      end
    end
  end

  def add_data_transfer
    raise NotImplementedError
  end

  def add_transfer_receipt
    instance = Epics::Builders::TransferReceiptBuilder.new do |instance|
      yield instance
    end
    @xml.parent.add_child(instance.doc)
    self
  end

  def doc
    @xml.doc.root
  end
end

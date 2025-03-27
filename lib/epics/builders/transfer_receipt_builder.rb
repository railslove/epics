class Epics::Builders::TransferReceiptBuilder
  def initialize
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      xml.TransferReceipt(authenticate: true) do
        yield self
      end
    end
  end

  def add_receipt_code(receipt_code)
    @xml.ReceiptCode receipt_code
    self
  end

  def doc
    @xml.doc.root
  end
end

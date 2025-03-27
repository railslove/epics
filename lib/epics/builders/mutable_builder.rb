class Epics::Builders::MutableBuilder
  PHASE_INITIALIZATION = 'Initialisation'
  PHASE_RECEIPT = 'Receipt'
  PHASE_TRANSFER = 'Transfer'

  def initialize
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      xml.mutable do
        yield self
      end
    end
  end

  def add_receipt_code(receipt_code)
    @xml.ReceiptCode receipt_code
    self
  end

  def add_transaction_phase(transaction_phase)
    @xml.TransactionPhase transaction_phase
    self
  end

  def add_segment_number(segment_number, is_last_segment = false)
    @xml.SegmentNumber segment_number, lastSegment: is_last_segment
    self
  end

  def doc
    @xml.doc.root
  end
end

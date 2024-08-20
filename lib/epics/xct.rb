class Epics::XCT < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'XCT'
      builder.order_attribute = 'OZHNN'
      builder.num_segments = 1
    end
  end
end

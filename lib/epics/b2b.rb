class Epics::B2B < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'B2B'
      builder.order_attribute = 'OZHNN'
      builder.num_segments = 1
    end
  end
end

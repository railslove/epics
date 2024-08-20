class Epics::CDD < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'CDD'
      builder.order_attribute = 'OZHNN'
      builder.num_segments = 1
    end
  end
end

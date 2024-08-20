class Epics::XE2 < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'XE2'
      builder.order_attribute = 'OZHNN'
      builder.num_segments = 1
    end
  end
end

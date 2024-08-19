class Epics::B2B < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'B2B'
      builder.order_attribute = 'OZHNN'
      builder.order_params = ''
      builder.num_segment = 1
    end
  end
end

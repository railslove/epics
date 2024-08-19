class Epics::XE2 < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'XE2'
      builder.order_attribute = 'OZHNN'
      builder.order_params = ''
      builder.num_segment = 1
    end
  end
end

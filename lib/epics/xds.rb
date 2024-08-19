class Epics::XDS < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'XDS'
      builder.order_attribute = 'OZHNN'
      builder.order_params = ''
      builder.num_segment = 1
    end
  end
end

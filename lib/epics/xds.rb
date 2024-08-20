class Epics::XDS < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'XDS'
      builder.order_attribute = 'OZHNN'
      builder.num_segments = 1
    end
  end
end

class Epics::CDS < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'CDS'
      builder.order_attribute = 'DZHNN'
      builder.order_params = ''
      builder.num_segment = 1
    end
  end
end

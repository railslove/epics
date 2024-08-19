class Epics::CCS < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'CCS'
      builder.order_attribute = 'DZHNN'
      builder.order_params = ''
      builder.num_segment = 1
    end
  end
end

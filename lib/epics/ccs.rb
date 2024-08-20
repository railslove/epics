class Epics::CCS < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'CCS'
      builder.order_attribute = 'DZHNN'
      builder.num_segments = 1
    end
  end
end

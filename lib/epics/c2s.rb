class Epics::C2S < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'C2S'
      builder.order_attribute = 'DZHNN'
      builder.num_segments = 1
    end
  end
end

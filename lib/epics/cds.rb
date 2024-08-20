class Epics::CDS < Epics::GenericUploadRequest
  def header
    super do |builder|
      builder.order_type = 'CDS'
      builder.order_attribute = 'DZHNN'
      builder.num_segments = 1
    end
  end
end

class Epics::Builders::DataTransferBuilder::V2 < Epics::Builders::DataTransferBuilder::Base
  def add_data_digest(signature_version, digest = nil)
    self
  end

  def add_additional_order_info
    self
  end
end

class Epics::Builders::DataTransferBuilder::V3 < Epics::Builders::DataTransferBuilder::Base
  def add_data_digest(signature_version, digest = nil)
    digest_value = digest ? Base64.strict_encode64(digest) : nil
    @xml.DataDigest digest_value, SignatureVersion: signature_version
    self
  end

  def add_additional_order_info
    @xml.AdditionalOrderInfo
    self
  end
end

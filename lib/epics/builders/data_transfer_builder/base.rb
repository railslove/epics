class Epics::Builders::DataTransferBuilder::Base
  def initialize
    @crypt_service = Epics::Services::CryptService.new
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      xml.DataTransfer do
        yield self
      end
    end
  end

  def add_order_data(order_data = nil, transaction_key = nil)
    content = if order_data
      order_data_compressed = Zlib::Deflate.deflate(order_data)

      Base64.strict_encode64(if transaction_key
        @crypt_service.encrypt_by_key(transaction_key, order_data_compressed)
      else
        order_data_compressed
      end)
    end
    @xml.OrderData content
    self
  end

  def add_data_encryption_info
    instance = Epics::Builders::DataEncryptionInfoBuilder.new do |instance|
      yield instance
    end
    @xml.parent.add_child(instance.doc)
    self
  end

  def add_signature_data(data, transaction_key)
    user_signature_compressed = Zlib::Deflate.deflate(data)
    user_signature_compressed_encrypted = @crypt_service.encrypt_by_key(transaction_key, user_signature_compressed)
    @xml.SignatureData Base64.strict_encode64(user_signature_compressed_encrypted), authenticate: true
    self
  end

  def doc
    @xml.doc.root
  end
end

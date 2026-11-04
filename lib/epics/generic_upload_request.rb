class Epics::GenericUploadRequest < Epics::GenericRequest
  attr_reader :document, :transaction_key

  def initialize(client, document, **options)
    super(client, **options)
    @document = document
    aes_factory = Epics::Factories::Crypt::AesFactory.new
    aes = aes_factory.create
    @transaction_key = aes.key
    @crypt_service = Epics::Services::CryptService.new
  end

  # The ES hash excludes CR and LF; the bank strips them before verifying. The order
  # data itself is transmitted unchanged.
  def document_digest
    @crypt_service.hash(document.gsub(/\n|\r/, ''))
  end

  def to_transfer_xml
    builder = request_factory.create_transfer_upload(transaction_id, transaction_key, document, 1, true)
    builder.to_xml
  end
end

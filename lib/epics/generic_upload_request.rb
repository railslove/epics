class Epics::GenericUploadRequest < Epics::GenericRequest
  attr_accessor :document
  attr_reader :transaction_key

  def initialize(client, document, **options)
    super(client, **options)
    self.document = document
    aes_factory = Epics::Factories::Crypt::AesFactory.new
    aes = aes_factory.create
    @transaction_key = aes.key
    @crypt_service = Epics::Services::CryptService.new
  end

  # Line endings are stripped before hashing so that the same logical document
  # always yields the same electronic signature.
  def document_digest
    @crypt_service.hash(normalized_document)
  end

  def normalized_document
    document.gsub(/\n|\r/, '')
  end

  def to_transfer_xml
    builder = request_factory.create_transfer_upload(transaction_id, transaction_key, document, 1, true)
    builder.to_xml
  end
end

class Epics::GenericUploadRequest < Epics::GenericRequest
  attr_reader :document, :transaction_key

  def initialize(client, document, **options)
    super(client, **options)
    self.document = document
    aes_factory = Epics::Factories::Crypt::AesFactory.new
    aes = aes_factory.create
    @transaction_key = aes.key
    @crypt_service = Epics::Services::CryptService.new
  end

  # Normalized on the way in so the bytes hashed for the electronic signature are the
  # bytes transmitted.
  def document=(value)
    @document = value.gsub(/\n|\r/, '')
  end

  def document_digest
    @crypt_service.hash(document)
  end

  def to_transfer_xml
    builder = request_factory.create_transfer_upload(transaction_id, transaction_key, document, 1, true)
    builder.to_xml
  end
end

class Epics::Builders::DataEncryptionInfoBuilder
  def initialize
    @crypt_service = Epics::Services::CryptService.new
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      xml.DataEncryptionInfo(authenticate: true) do
        yield self
      end
    end
  end

  def add_encryption_pubkey_digest(keyring, algorithm = 'sha256')
    resolver = Epics::Services::DigestResolver::Base.for_version(keyring.version)
    certificate_digest = resolver.sign_digest(keyring.bank_encryption, algorithm)
    attribues = { Version: keyring.bank_encryption.version, Algorithm: "http://www.w3.org/2001/04/xmlenc##{algorithm}" }
    @xml.EncryptionPubKeyDigest Base64.strict_encode64(certificate_digest), **attribues
    self
  end

  def add_transaction_key(transaction_key, keyring)
    transaction_key_encrypted = @crypt_service.encrypt_transaction_key(keyring.bank_encryption.key, transaction_key)
    @xml.TransactionKey Base64.strict_encode64(transaction_key_encrypted)
    self
  end

  def doc
    @xml.doc.root
  end
end

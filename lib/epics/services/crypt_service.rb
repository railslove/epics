class Epics::Services::CryptService
  def initialize
    @aes_factory = Epics::Factories::Crypt::AesFactory.new
  end

  def encrypt(signature, data)
    case signature.version
    when Epics::Signature::A_VERSION_6, Epics::Signature::X_VERSION_2
      signature.key.sign(data)
    when Epics::Signature::A_VERSION_5
      encrypt_by_rsa(signature.key, data)
    end
  end

  def decrypt_by_key(key, encrypted)
    aes = @aes_factory.create
    aes.key_length = 128
    aes.key = key
    aes.decrypt(encrypted)
  end

  def encrypt_by_key(key, data)
    aes = @aes_factory.create
    aes.key_length = 128
    aes.key = key
    aes.encrypt(data)
  end

  def encrypt_transaction_key(key, transaction_key)
    encrypt_by_rsa_public_key(key, transaction_key)
  end

  def hash(text, algorithm = 'sha256')
    OpenSSL::Digest.digest(algorithm, text)
  end

  def calculate_digest(signature, algorithm = 'sha256')
    exponent = signature.exponent.to_s(16)
    modulus = signature.modulus.to_s(16)
    key = calculate_key(exponent, modulus)

    hash(key, algorithm)
  end

  def calculate_key(exponent, modulus)
    [exponent.gsub(/^0*/,''), modulus.gsub(/^0*/,'')].map(&:downcase).join(' ')
  end

  private

  def encrypt_by_rsa_public_key(key, data)
    key.encrypt(data)
  end

  def encrypt_by_rsa(key, data)
    key.private_encrypt(data)
  end
end
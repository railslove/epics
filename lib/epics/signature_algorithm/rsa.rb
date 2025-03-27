class Epics::SignatureAlgorithm::Rsa < Epics::SignatureAlgorithm::Base
  HASH_ALGORITHM = 'sha256'

  def initialize(encoded_key, passphrase = nil)
    if encoded_key.kind_of?(OpenSSL::PKey::RSA)
      self.key = encoded_key
    else
      self.key = OpenSSL::PKey::RSA.new(encoded_key)
    end
  end

  def exponent
    key.e
  end

  # TODO: remove this method
  def e
    exponent.to_s(16)
  end

  def modulus
    key.n
  end

  # TODO: remove this method
  def n
    modulus.to_s(16)
  end

  def mgf1_hash_algorithm
    OpenSSL::Digest.new(HASH_ALGORITHM)
  end

  def hash_algorithm
    OpenSSL::Digest.new(HASH_ALGORITHM)
  end

  def encrypt(data)
    key.public_encrypt(data)
  end

  def private_encrypt(data)
    key.private_encrypt(data)
  end

  # TODO: remove this method
  def digester
    @digester ||= OpenSSL::Digest::SHA256.new
  end
end

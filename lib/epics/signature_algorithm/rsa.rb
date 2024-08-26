class Epics::SignatureAlgorithm::Rsa < Epics::SignatureAlgorithm::Base
  HASH_ALGORITHM = 'SHA256'

  def initialize(encoded_key, passphrase = nil)
    if encoded_key.kind_of?(OpenSSL::PKey::RSA)
      self.key = encoded_key
    else
      self.key = OpenSSL::PKey::RSA.new(encoded_key)
    end
  end

  def n
    self.key.n.to_s(16)
  end

  def e
    self.key.e.to_s(16)
  end

  def sign(msg)
    key.sign(
      hash_algorithm,
      msg
    )
  end

  def verify(signature, msg)
    key.verify(
      hash_algorithm,
      Base64.decode64(signature),
      msg
    )
  end

  def hash_algorithm
    HASH_ALGORITHM
  end

  def digester
    @digester ||= OpenSSL::Digest::SHA256.new
  end
end

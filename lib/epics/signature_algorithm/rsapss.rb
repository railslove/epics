class Epics::SignatureAlgorithm::RsaPss < Epics::SignatureAlgorithm::Rsa
  def sign(msg)
    key.sign_pss(
      hash_algorithm,
      msg,
      salt_length: :digest,
      mgf1_hash:   mgf1_hash_algorithm,
    )
  end

  def verify(signature, msg)
    key.verify_pss(
      hash_algorithm,
      Base64.decode64(signature),
      msg,
      salt_length: :digest,
      mgf1_hash:   mgf1_hash_algorithm,
    )
  end

  def mgf1_hash_algorithm
    HASH_ALGORITHM
  end
end

class Epics::SignatureAlgorithm::RsaPkcs1 < Epics::SignatureAlgorithm::Rsa
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
end

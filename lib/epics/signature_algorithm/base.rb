class Epics::SignatureAlgorithm::Base
  attr_accessor :key

  def initialize(encoded_key, passphrase = nil)
    self.key = encoded_key
  end

  ###
  # concat the exponent and modulus (hex representation) with a single whitespace
  # remove leading zeros from both
  # calculate digest (SHA256)
  # encode as Base64
  ####
  def public_digest
    c = [ e.gsub(/^0*/,''), n.gsub(/^0*/,'') ].map(&:downcase).join(" ")

    Base64.encode64(digester.digest(c)).strip
  end

  def n
    raise NotImplementedError
  end

  def e
    raise NotImplementedError
  end

  def sign(msg)
    raise NotImplementedError
  end

  def verify(signature, msg)
    raise NotImplementedError
  end

  def digester
    raise NotImplementedError
  end
end

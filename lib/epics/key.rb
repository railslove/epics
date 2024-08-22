class Epics::Key
  attr_accessor :key

  def initialize(encoded_key, passphrase = nil)
    if encoded_key.kind_of?(OpenSSL::PKey::RSA)
      self.key = encoded_key
    else
      self.key = OpenSSL::PKey::RSA.new(encoded_key)
    end
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
    self.key.n.to_s(16)
  end

  def e
    self.key.e.to_s(16)
  end

  def sign(msg)
    Base64.encode64(
      key.sign_pss(
        'SHA256',
        msg,
        salt_length: :digest,
        mgf1_hash:   'SHA256',
        ),
      ).gsub("\n", '')
  end

  def digester
    @digester ||= OpenSSL::Digest::SHA256.new
  end

end

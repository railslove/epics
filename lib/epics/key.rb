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

  def sign(msg, salt = OpenSSL::Random.random_bytes(32) )
    Base64.encode64(mod_pow(OpenSSL::BN.new(emsa_pss(msg, salt).to_s, 2), self.key.d, self.key.n).to_s(2)).gsub("\n", "")
  end

  def recover(msg)
    mod_pow(OpenSSL::BN.new(msg.to_s, 2), self.key.e, self.key.n).to_s(2)
  end

  def digester
    @digester ||= OpenSSL::Digest::SHA256.new
  end

  private

  ##
  # http://de.wikipedia.org/wiki/Probabilistic_Signature_Scheme
  ##
  def emsa_pss(msg, salt)
    m_tick_hash = digester.digest [("\x00" * 8), digester.digest(msg), salt].join

    ps = "\x00" * 190
    db = [ps, "\x01", salt].join

    db_mask   = Epics::MGF1.new.generate(m_tick_hash, db.size)
    masked_db = Epics::MGF1.new.xor(db, db_mask)

    masked_db_msb = OpenSSL::BN.new(masked_db[0], 2).to_i.to_s(2).rjust(8, "0")
    masked_db_msb[0] = "0"

    masked_db[0] = OpenSSL::BN.new(masked_db_msb.to_i(2).to_s).to_s(2)

    [masked_db, m_tick_hash, ["BC"].pack("H*") ].join
  end

  def mod_pow(base, power, mod)
    base  = base.to_i
    power = power.to_i
    mod   = mod.to_i
    result = 1
    while power > 0
      result = (result * base) % mod if power & 1 == 1
      base = (base * base) % mod
      power >>= 1
    end
    OpenSSL::BN.new(result.to_s)
  end

end

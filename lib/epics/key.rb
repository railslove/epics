class Epics::Key
  attr_accessor :key

  def initialize(file, passphrase = nil)
    self.key = OpenSSL::PKey::RSA.new(File.read(file))
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

  def digester
    @digester ||= OpenSSL::Digest::SHA256.new
  end

end
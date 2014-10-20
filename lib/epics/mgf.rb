class Epics::MGF1
  def initialize(digest = OpenSSL::Digest::SHA256)
    @digest = digest.new
    @hlen = 32
  end

  def generate(seed, masklen)
    if masklen > (2 << 31) * @hlen
      raise ArgumentError, "mask too long"
    end
    t = ""
    divceil(masklen, @hlen).times do |counter|
      t += @digest.digest(seed + i2osp(counter, 4))
    end
    t[0, masklen]
  end

  def i2osp(x, len)
    if x >= 256 ** len
      raise ArgumentError, "integer too large"
    end
    [x].pack("N").gsub(/^\x00+/, '').rjust(len, "\x00")
  end

  def divceil(a, b)
    (a + b - 1) / b
  end

  def xor(a, b)
    if a.size != b.size
      raise ArgumentError, "different length for a and b"
    end
    a = a.unpack('C*')
    b = b.unpack('C*')
    a.size.times do |idx|
      a[idx] ^= b[idx]
    end
    a.pack("C*")
  end

end

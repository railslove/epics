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
      t += dohash(seed + i2osp(counter, 4))
    end
    t[0, masklen]
  end

  def i2osp(x, len)
    if x >= 256 ** len
      raise ArgumentError, "integer too large"
    end
    os = to_bytes(x).sub(/^\x00+/, '')
    "\x00" * (len - os.size) + os
  end

  def to_bytes(num)
    # 4 byte alignment needed like; divceil(bignum.size, 4) * 4
    # In CRuby, we can expect Bignum#size aligns but the returned value
    # depends on internal representation across Ruby implementations.
    # For example, (2**64).size == 12 in CRuby but 9 in JRuby and Rubinius.
    bits = divceil(num.size, 4) * 4 * 8
    pos = value = 0
    str = ""
    (0..(bits - 1)).each do |idx|
      if num[idx].nonzero?
        value |= (num[idx] << pos)
      end
      pos += 1
      if pos == 32
        str = [value].pack("N") + str
        pos = value = 0
      end
    end
    str
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

private

  def dohash(msg)
    @digest.digest(msg)
  end

end

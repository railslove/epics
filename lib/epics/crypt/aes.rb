class Epics::Crypt::Aes
  attr_writer :key, :key_length

  def initialize
    @cipher = {}
  end

  def decrypt(encrypted)
    cipher = use_cipher(:decrypt)
    unpad(cipher.update(encrypted) + cipher.final)
  end

  def encrypt(plaintext)
    cipher = use_cipher(:encrypt)
    cipher.update(pad(cipher, plaintext)) + cipher.final
  end

  def key
    @key ||= create_cipher.random_key
  end

  def key_length
    @key_length ||= 128
  end

  private

  def create_cipher
    @cipher[key_length] ||= OpenSSL::Cipher::AES.new(key_length, :CBC).tap do |cipher|
      cipher.padding = 0
      cipher.iv = 0.chr * cipher.iv_len
    end
  end

  def use_cipher(method)
    create_cipher.tap do |cipher|
      cipher.reset
      cipher.send(method)
      cipher.key = key
    end
  end

  def pad(cipher, text)
    len = cipher.block_size * ((text.size / cipher.block_size) + 1)

    text.ljust(len, [0].pack('C*')).tap do |padded|
      padded[-1] = [len - text.size].pack('C*')
    end
  end

  def unpad(text)
    len = text[-1].unpack('C*').first

    text[0...-len]
  end
end

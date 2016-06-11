class Epics::Signer_cert

  def signature(key, doc)
    
    h = 32
    s = h
    k = key.n.num_bits  #length of n in bits
    em_bits = k - 1  #length of dsi in bits
    n_length = key.n.num_bytes #length of n in byte
    em_len = em_bits / 8  #length of dsi in byte

    #step one create hash
    m_hash = OpenSSL::Digest::SHA256.digest(h3k_request_order_data)

    #step two create dsi
    salt = OpenSSL::Random.random_bytes(s)
    m_tick = [("\x00" * 8), m_hash, salt].join 
    m_tick_hash = hash(m_tick)
    ps = "\x00" * (em_len - h - s - 2)  #em_len = length of dsirequire 'byebug'
    db = [ps, "\x01", salt].join #length shold be em_len - h - 1
    


    ### Code by Lars Brillert
    db_mask = Epics::MGF1.new.generate(m_tick_hash, em_len - h - 1)
    
    masked_db = Epics::MGF1.new.xor(db, db_mask)
    masked_db_msb = OpenSSL::BN.new(masked_db[0], 2).to_i.to_s(2).rjust(8, "0")
    masked_db_msb[0] = "0"
    masked_db[0] = OpenSSL::BN.new(masked_db_msb.to_i(2).to_s).to_s(2)

    dsi = [masked_db, m_tick_hash, ["BC"].pack("H*") ].join
    ###



    #step three create signature over dsi
    sign(dsi, key)
  end

  ###   Helper Methods from the block above    ###
  def sign(dsi, key)
    mod_pow(dsi, key.d, key.n) #Lars takes key.e instaed of key.d??? key.e should be the public key  
  end




  ### Code by Lars Brillert
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
  ###

end

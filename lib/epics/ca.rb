class Epics::CA
  def initialize(client)
    @client = client
  end

  def certificate(key_ref)
    key = @client.keys[key_ref].key
    subject = OpenSSL::X509::Name.parse("/C=DE/CN=#{@client.user_id}") # CN shall be the client's name
    cert = OpenSSL::X509::Certificate.new
    cert.version = 3
    cert.serial = rand.to_s[2..8].to_i # rand number for prototype version only
    cert.subject = subject
    cert.issuer = subject # self signed
    cert.public_key = key.public_key
    cert.not_before = Time.now
    cert.not_after = cert.not_before + 1 * 365 * 24 * 60 * 60 # 1 years validity
    cert.sign(key, OpenSSL::Digest::SHA256.new)
  end
end

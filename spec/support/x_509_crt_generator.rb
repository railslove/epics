def generate_x_509_crt(key, distinguished_name)
  name = OpenSSL::X509::Name.parse(distinguished_name)

  cert = OpenSSL::X509::Certificate.new
  cert.version = 2
  cert.serial = 1
  cert.subject = name
  cert.issuer = name
  cert.public_key = key.public_key
  cert.not_before = Time.now
  cert.not_after = cert.not_before + 365 * 24 * 60 * 60

  ef = OpenSSL::X509::ExtensionFactory.new
  ef.subject_certificate = cert
  ef.issuer_certificate = cert
  cert.add_extension(ef.create_extension("basicConstraints", "CA:FALSE", true))
  cert.add_extension(ef.create_extension("keyUsage", "digitalSignature,keyEncipherment,nonRepudiation", true))

  cert.sign(key, OpenSSL::Digest::SHA256.new)

  cert.to_pem
end
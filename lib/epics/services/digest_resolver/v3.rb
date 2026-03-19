class Epics::Services::DigestResolver::V3 < Epics::Services::DigestResolver::Base
  def sign_digest(signature, algorithm = 'sha256')
    if signature.certificate
      @crypt_service.calculate_certificate_fingerprint(signature.certificate, algorithm)
    else
      warn '[epics] WARNING: EBICS 3.0 sign_digest falling back to key-based digest ' \
           "for #{signature.version}. Bank certificate may be missing -- consider running HPB."
      @crypt_service.calculate_digest(signature.key, algorithm)
    end
  end

  def confirm_digest(signature, algorithm = 'sha256')
    bin2hex(if signature.certificate
              @crypt_service.calculate_certificate_fingerprint(signature.certificate, algorithm)
            else
              @crypt_service.calculate_digest(signature.key, algorithm)
            end)
  end
end

class Epics::Services::DigestResolver::V2 < Epics::Services::DigestResolver::Base
  def sign_digest(signature, algorithm = 'sha256')
    @crypt_service.calculate_digest(signature.key, algorithm)
  end

  def confirm_digest(signature, algorithm = 'sha256')
    bin2hex(if signature.certificate
      @crypt_service.calculate_certificate_fingerprint(signature.certificate, algorithm)
    else
      @crypt_service.calculate_digest(signature.key, algorithm)
    end)
  end
end

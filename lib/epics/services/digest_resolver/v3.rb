class Epics::Services::DigestResolver::V3 < Epics::Services::DigestResolver::Base
  def sign_digest(signature, algorithm = 'sha256')
    @crypt_service.calculate_certificate_fingerprint(signature.certificate, algorithm)
  end

  def confirm_digest(signature, algorithm = 'sha256')
    bin2hex(@crypt_service.calculate_certificate_fingerprint(signature.certificate, algorithm))
  end
end

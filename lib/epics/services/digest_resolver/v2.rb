class Epics::Services::DigestResolver::V2 < Epics::Services::DigestResolver::Base
  def sign_digest(signature, algorithm = 'sha256')
    @crypt_service.calculate_digest(signature, algorithm)
  end

  def confirm_digest(signature, algorithm = 'sha256')
    @crypt_service.calculate_digest(signature, algorithm)
  end
end

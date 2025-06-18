class Epics::Services::DigestResolver::Base
  def initialize
    @crypt_service = Epics::Services::CryptService.new
  end

  def sign_digest(signature, algorithm = 'sha256')
    raise NotImplementedError
  end

  def confirm_digest(signature, algorithm = 'sha256')
    raise NotImplementedError
  end

  private

  def bin2hex(date)
    date.unpack('H*').first
  end
end

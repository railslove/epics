class Epics::Services::DigestResolver::Base
  def self.for_version(version)
    case version
    when Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25
      Epics::Services::DigestResolver::V2.new
    when Epics::Keyring::VERSION_30
      Epics::Services::DigestResolver::V3.new
    else
      raise ArgumentError, "Unsupported EBICS version for DigestResolver: #{version}"
    end
  end

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
    date.unpack1('H*')
  end
end

class Epics::Keyring
  VERSION_24 = 'H003'
  VERSION_25 = 'H004'
  VERSION_30 = 'H005'

  VERSIONS = [VERSION_24, VERSION_25, VERSION_30]

  attr_reader :version
  attr_accessor :user_signature, :user_encryption, :user_authentication
  attr_accessor :bank_encryption, :bank_authentication
  attr_accessor :password

  def initialize(version)
    raise ArgumentError, "Unsupported version: #{version}" unless VERSIONS.include?(version)

    @version = version
  end
end
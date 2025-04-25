class Epics::Keyring
  VERSION_24 = 'H003'
  VERSION_25 = 'H004'
  
  SUPPORTED_VERSIONS = [VERSION_24, VERSION_25]
  
  attr_reader :version
  
  def initialize(version)
    raise ArgumentError, "Unsupported version: #{version}" unless SUPPORTED_VERSIONS.include?(version)
    
    @version = version
  end
end
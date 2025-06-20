class Epics::Signature
  A_VERSION_5 = 'A005'
  A_VERSION_6 = 'A006'
  E_VERSION_2 = 'E002'
  X_VERSION_2 = 'X002'

  A_VERSIONS = [A_VERSION_5, A_VERSION_6]
  E_VERSIONS = [E_VERSION_2]
  X_VERSIONS = [X_VERSION_2]

  TYPE_A = 'A'
  TYPE_X = 'X'
  TYPE_E = 'E'

  TYPES = [TYPE_A, TYPE_X, TYPE_E]

  attr_reader :type, :version
  attr_accessor :key, :certificate

  def initialize(version, key)
    self.key = key
    self.version = version
  end

  def version=(value)
    @type = value[0]
    raise UnknownTypeError, type unless TYPES.include?(type)

    @version = value
    raise UnknownVersionError, version unless self.class.const_get("#{type}_VERSIONS").include?(version)
  end

  class UnknownVersionError < StandardError
    attr_reader :version

    def initialize(version)
      @version = version
      super("Unsupported version: #{version}")
    end
  end

  class UnknownTypeError < StandardError
    attr_reader :type

    def initialize(type)
      @type = type
      super("Unsupported type: #{type}")
    end
  end
end

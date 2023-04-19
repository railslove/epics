module Epics
  class Configuration
    PARAMETERS = {
      product_name: 'EPICS - a ruby ebics kernel',
      locale: :de,
    }.freeze

    attr_accessor(*PARAMETERS.keys)

    def initialize
      PARAMETERS.each { |attr, value| public_send("#{attr}=", value) }
    end
  end
end

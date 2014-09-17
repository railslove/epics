require 'faraday_middleware/response_middleware'

class Epics::ParseEbics < FaradayMiddleware::ResponseMiddleware
    class_attribute :client

    def initialize(app = nil, options = {})
      super
      self.class.client = @options[:client]
    end

    define_parser do |body|
      ::Epics::Response.new(client, body) unless body.strip.empty?
    end
end

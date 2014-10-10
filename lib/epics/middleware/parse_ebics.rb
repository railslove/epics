require 'faraday_middleware/response_middleware'

class Epics::ParseEbics < Faraday::Middleware
  def initialize(app = nil, options = {})
    @app = app
    @client = options[:client]
    super(app)
  end

  def call(env)
    @app.call(env).on_complete do |env|
      env[:body] = ::Epics::Response.new(@client, env[:body])
    end
  end
end

class Epics::ParseEbics < Faraday::Middleware

  def initialize(app = nil, options = {})
    super(app)
    @client = options[:client]
  end

  def call(env)
    @app.call(env).on_complete do |env|
      env[:body] = ::Epics::Response.new(@client, env[:body])
    end
  end
end

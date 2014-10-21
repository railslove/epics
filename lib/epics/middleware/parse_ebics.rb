class Epics::ParseEbics < Faraday::Middleware

  def initialize(app = nil, options = {})
    super(app)
    @client = options[:client]
  end

  def call(env)
    @app.call(env).on_complete do |env|
      env[:body] = ::Epics::Response.new(@client, env[:body])
      raise Epics::Error::TechnicalError.new(env[:body].technical_code) if env[:body].technical_error?
      raise Epics::Error::BusinessError.new(env[:body].business_code)  if env[:body].business_error?
    end
  end
end

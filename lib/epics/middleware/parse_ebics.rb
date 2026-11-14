# frozen_string_literal: true

class Epics::ParseEbics < Faraday::Middleware
  def initialize(app = nil, options = {})
    super(app)
    @client = options[:client]
  end

  def call(env)
    @app.call(env).on_complete do |response|
      raise(Epics::Error::HTTPError.new(response.status, response.body)) unless (200..299).cover?(response.status)

      body = response.body
      response.body = ::Epics::Response.new(@client, body)
      raise(Epics::Error::UnexpectedResponse, body) unless response.body.ebics?
      raise(Epics::Error::TechnicalError, response.body.technical_code) if response.body.technical_error?
      raise(Epics::Error::BusinessError, response.body.business_code)   if response.body.business_error?
    end
  end
end

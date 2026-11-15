# frozen_string_literal: true

class Epics::ParseEbics < Faraday::Middleware
  def initialize(app = nil, options = {})
    super(app)
    @client = options[:client]
  end

  def call(env)
    @app.call(env).on_complete do |response|
      raise_http_error(response) unless response.success?

      raw_body = response.body
      response.body = ::Epics::Response.new(@client, raw_body)
      raise_for_return_code(response.body, raw_body)
    end
  end

  private

  def raise_http_error(response)
    raise(Epics::Error::HTTPError.new(response.status, response.body))
  end

  def raise_for_return_code(ebics_response, raw_body)
    raise(Epics::InvalidResponseError.new('ReturnCode', body: raw_body)) if ebics_response.technical_code.empty?
    raise(Epics::Error::TechnicalError, ebics_response.technical_code) if ebics_response.technical_error?
    raise(Epics::Error::BusinessError, ebics_response.business_code)   if ebics_response.business_error?
  end
end

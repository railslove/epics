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

  # Epics::Client#post puts the phase, the order type and whether order data was sent into
  # the request context. A request posted without it is unknown, so retryable? says no.
  def raise_http_error(response)
    request = response.request&.context&.[](:epics_request)
    raise(Epics::Error::HTTPError.new(response.status, response.body,
                                      reason_phrase: response.reason_phrase,
                                      request_known: !request.nil?,
                                      **request.to_h))
  end

  def raise_for_return_code(ebics_response, raw_body)
    raise(Epics::InvalidResponseError.new('ReturnCode', body: raw_body)) if ebics_response.technical_code.empty?
    raise(Epics::Error::TechnicalError, ebics_response.technical_code) if ebics_response.technical_error?
    raise(Epics::Error::BusinessError, ebics_response.business_code)   if ebics_response.business_error?
  end
end

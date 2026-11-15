# frozen_string_literal: true

class Epics::ParseEbics < Faraday::Middleware
  # local-name() reads H003, H004 and H005 alike, so a namespace other than the client's
  # cannot hide the phase or the order data and turn an upload into a retryable request.
  PHASE_XPATH = "//*[local-name()='header']/*[local-name()='mutable']/*[local-name()='TransactionPhase']"
  # H003 and H004 name the order type OrderType, H005 AdminOrderType.
  ORDER_TYPE_XPATH = "//*[local-name()='header']/*[local-name()='static']/*[local-name()='OrderDetails']" \
                     "/*[local-name()='OrderType' or local-name()='AdminOrderType']"
  # Only an ebicsRequest carries an order. INI and HIA send their keys as OrderData in an
  # ebicsUnsecuredRequest, and sending a key again cannot make the bank act twice.
  ORDER_DATA_XPATH = "/*[local-name()='ebicsRequest']/*[local-name()='body']" \
                     "/*[local-name()='DataTransfer']/*[local-name()='OrderData']"

  def initialize(app = nil, options = {})
    super(app)
    @client = options[:client]
  end

  def call(env)
    # Faraday 1.x replaces env.body with the response body and has no env.request_body.
    request_body = env.body

    @app.call(env).on_complete do |response|
      raise_http_error(response, request_body) unless response.success?

      raw_body = response.body
      response.body = ::Epics::Response.new(@client, raw_body)
      raise_for_return_code(response.body, raw_body)
    end
  end

  private

  def raise_http_error(response, request_body)
    request = Nokogiri::XML(request_body.to_s)
    raise(Epics::Error::HTTPError.new(response.status, response.body,
                                      reason_phrase: response.reason_phrase,
                                      phase: request_text(request, PHASE_XPATH),
                                      order_type: request_text(request, ORDER_TYPE_XPATH),
                                      order_data_sent: !request_text(request, ORDER_DATA_XPATH).nil?))
  end

  def raise_for_return_code(ebics_response, raw_body)
    raise(Epics::InvalidResponseError.new('ReturnCode', body: raw_body)) if ebics_response.technical_code.empty?
    raise(Epics::Error::TechnicalError, ebics_response.technical_code) if ebics_response.technical_error?
    raise(Epics::Error::BusinessError, ebics_response.business_code)   if ebics_response.business_error?
  end

  def request_text(request, xpath)
    request.at_xpath(xpath)&.text
  end
end

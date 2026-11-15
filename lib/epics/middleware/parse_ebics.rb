# frozen_string_literal: true

class Epics::ParseEbics < Faraday::Middleware
  PHASE_XPATH = '//xmlns:header/xmlns:mutable/xmlns:TransactionPhase'
  # H003 and H004 name the order type OrderType, H005 AdminOrderType.
  ORDER_TYPE_XPATH = '//xmlns:header/xmlns:static/xmlns:OrderDetails/xmlns:OrderType | ' \
                     '//xmlns:header/xmlns:static/xmlns:OrderDetails/xmlns:AdminOrderType'
  ORDER_DATA_XPATH = '//xmlns:body/xmlns:DataTransfer/xmlns:OrderData'

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
    request.at_xpath(xpath, xmlns: @client.urn_schema)&.text
  end
end

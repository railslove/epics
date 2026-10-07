class Epics::GenericRequest
  extend Forwardable
  attr_reader :client, :options
  attr_accessor :transaction_id

  def initialize(client, **options)
    @client = client
    @options = options
  end

  def request_factory
    @request_factory ||= case client.version
    when Epics::Keyring::VERSION_25
      Epics::Factories::RequestFactory::V25.new(client)
    when Epics::Keyring::VERSION_24
      Epics::Factories::RequestFactory::V24.new(client)
    when Epics::Keyring::VERSION_30
      Epics::Factories::RequestFactory::V3.new(client)
    end
  end

  def order_data_handle
    @order_data_handle ||= case client.version
    when Epics::Keyring::VERSION_25
      Epics::Handlers::OrderDataHandler::V25.new(client)
    when Epics::Keyring::VERSION_24
      Epics::Handlers::OrderDataHandler::V24.new(client)
    when Epics::Keyring::VERSION_30
      Epics::Handlers::OrderDataHandler::V3.new(client)
    end
  end

  # BTF service parameters for the request, i.e. everything but the date range.
  # Compacted so unset options fall through to the factory defaults.
  def service_options
    options.except(:from, :to).compact
  end

  def nonce
    SecureRandom.hex(16)
  end

  def timestamp
    Time.now.utc.iso8601
  end

  def_delegators :client, :host_id, :user_id, :partner_id

  def to_transfer_xml
    raise NotImplementedError
  end

  def to_transfer_download_xml(segment_number, is_last_segment)
    builder = request_factory.create_transfer_download(transaction_id, segment_number, is_last_segment)
    builder.to_xml
  end

  def to_receipt_xml(acknowledged: true)
    builder = request_factory.create_transfer_receipt(transaction_id, acknowledged ? 0 : 1)
    builder.to_xml
  end

  def to_xml
    raise NotImplementedError
  end
end

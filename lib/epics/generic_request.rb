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
    end
  end

  def order_data_handle
    @order_data_handle ||= case client.version
    when Epics::Keyring::VERSION_25
      Epics::Handlers::OrderDataHandler::V25.new(client)
    when Epics::Keyring::VERSION_24
      Epics::Handlers::OrderDataHandler::V24.new(client)
    end
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

  def to_receipt_xml
    builder = request_factory.create_transfer_receipt(transaction_id, 0)
    builder.to_xml
  end

  def to_xml
    raise NotImplementedError
  end
end

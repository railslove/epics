class Epics::GenericRequest
  extend Forwardable
  attr_accessor :client

  def initialize(client)
    self.client = client
  end

  def nonce
    SecureRandom.hex(16)
  end

  def timestamp
    Time.now.utc.iso8601
  end

  def_delegators :client, :host_id, :user_id, :partner_id
end

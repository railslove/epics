class Epics::HeaderRequest
  extend Forwardable
  attr_accessor :client

  def initialize(client)
    self.client = client
  end

  def_delegators :client, :host_id, :user_id, :partner_id

  def build(options = {})
    options[:with_bank_pubkey_digests] = true if options[:with_bank_pubkey_digests].nil?
    options[:security_medium] = 0 if options[:security_medium].nil?

    Nokogiri::XML::Builder.new do |xml|
      xml.header(authenticate: true) {
        xml.static {
          xml.HostID host_id
          xml.Nonce options[:nonce] if options[:nonce]
          xml.Timestamp options[:timestamp] if options[:timestamp]
          xml.PartnerID partner_id
          xml.UserID user_id
          xml.Product(client.product_name, 'Language' => client.locale)
          xml.OrderDetails {
            xml.OrderType options[:order_type]
            xml.OrderID b36encode(client.next_order_id) if client.version == Epics::Client::VERSION_H3
            xml.OrderAttribute options[:order_attribute]
            xml.StandardOrderParams {
              build_attributes(xml, options[:order_params])
            } if options[:order_params]
            build_attributes(xml, options[:custom_order_params]) if options[:custom_order_params]
          }
          xml.BankPubKeyDigests {
            xml.Authentication(client.bank_authentication_key.public_digest, Version: client.authentication_version, Algorithm: 'http://www.w3.org/2001/04/xmlenc#sha256')
            xml.Encryption(client.bank_encryption_key.public_digest, Version: client.encryption_version, Algorithm: 'http://www.w3.org/2001/04/xmlenc#sha256')
          } if options[:with_bank_pubkey_digests]
          xml.SecurityMedium b36encode(options[:security_medium]) if options[:security_medium]
          xml.NumSegments options[:num_segments] if options[:num_segments]
        }
        xml.mutable {
          build_attributes(xml, options[:mutable])
        } if options[:mutable]
      }
    end.doc.root
  end

  private

  def build_attributes(xml, attributes)
    attributes.each do |key, value|
      if value.is_a?(Hash)
        xml.send(key) {
          build_attributes(xml, value)
        }
      else
        xml.send(key, value)
      end
    end
  end

  def b36encode(number)
    number.to_s(36).upcase.rjust(4, '0')
  end
end

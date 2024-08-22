class Epics::HeaderRequest
  extend Forwardable
  attr_accessor :client

  PRODUCT_NAME = 'EPICS - a ruby ebics kernel'
  PRODUCT_LANG = 'de'

  def initialize(client)
    self.client = client
  end

  def_delegators :client, :host_id, :user_id, :partner_id

  def build(options = {})
    options[:with_bank_pubkey_digests] = true if options[:with_bank_pubkey_digests].nil?

    Nokogiri::XML::Builder.new do |xml|
      xml.header(authenticate: true) {
        xml.static {
          xml.HostID host_id
          xml.Nonce options[:nonce] if options[:nonce]
          xml.Timestamp options[:timestamp] if options[:timestamp]
          xml.PartnerID partner_id
          xml.UserID user_id
          xml.Product(PRODUCT_NAME, 'Language' => PRODUCT_LANG)
          xml.OrderDetails {
            xml.OrderType options[:order_type]
            xml.OrderAttribute options[:order_attribute]
            xml.StandardOrderParams {
              build_attributes(xml, options[:order_params])
            } if options[:order_params]
          }
          xml.BankPubKeyDigests {
            xml.Authentication(client.bank_x.public_digest, Version: 'X002', Algorithm: 'http://www.w3.org/2001/04/xmlenc#sha256')
            xml.Encryption(client.bank_e.public_digest, Version: 'E002', Algorithm: 'http://www.w3.org/2001/04/xmlenc#sha256')
          } if options[:with_bank_pubkey_digests]
          xml.SecurityMedium '0000'
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
end

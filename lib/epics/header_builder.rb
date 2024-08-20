class Epics::HeaderBuilder
  extend Forwardable
  attr_accessor :client

  PRODUCT_NAME = 'EPICS - a ruby ebics kernel'
  PRODUCT_LANG = 'de'

  def initialize(client)
    self.client = client
  end

  def_delegators :client, :host_id, :user_id, :partner_id

  def build(options = {})
    options[:order_params] = ->(xml) {} if options[:order_params].nil?
    options[:with_bank_pubkey_digests] = true if options[:with_bank_pubkey_digests].nil?
    options[:mutable] = ->(xml) { xml.TransactionPhase 'Initialisation' } if options[:mutable].nil?

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
              options[:order_params].call(xml)
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
          options[:mutable].call(xml)
        } if options[:mutable]
      }
    end.doc.root
  end
end
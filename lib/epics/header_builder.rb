class Epics::HeaderBuilder
  extend Forwardable
  attr_accessor :client
  attr_accessor :order_type, :order_attribute, :order_params
  attr_accessor :num_segments, :mutable, :with_bank_pubkey_digests
  attr_accessor :nonce, :timestamp

  PRODUCT_NAME = 'EPICS - a ruby ebics kernel'
  PRODUCT_LANG = 'de'

  def initialize(client)
    self.client = client
    self.order_params = ->(xml) {}
    self.with_bank_pubkey_digests = true
    self.mutable = ->(xml) { xml.TransactionPhase 'Initialisation' }
  end

  def_delegators :client, :host_id, :user_id, :partner_id

  def build
    Nokogiri::XML::Builder.new do |xml|
      xml.header(authenticate: true) {
        xml.static {
          xml.HostID host_id
          xml.Nonce nonce if nonce
          xml.Timestamp timestamp if timestamp
          xml.PartnerID partner_id
          xml.UserID user_id
          xml.Product(PRODUCT_NAME, 'Language' => PRODUCT_LANG)
          xml.OrderDetails {
            xml.OrderType order_type
            xml.OrderAttribute order_attribute
            xml.StandardOrderParams {
              order_params.call(xml)
            } if order_params
          }
          xml.BankPubKeyDigests {
            xml.Authentication(client.bank_x.public_digest, Version: 'X002', Algorithm: 'http://www.w3.org/2001/04/xmlenc#sha256')
            xml.Encryption(client.bank_e.public_digest, Version: 'E002', Algorithm: 'http://www.w3.org/2001/04/xmlenc#sha256')
          } if with_bank_pubkey_digests
          xml.SecurityMedium '0000'
          xml.NumSegments num_segments if num_segments
        }
        xml.mutable {
          mutable.call(xml)
        } if mutable
      }
    end.doc.root
  end
end
class Epics::HeaderBuilder
  extend Forwardable
  attr_accessor :client
  attr_accessor :order_type, :order_attribute, :order_params
  attr_accessor :num_segment, :mutable, :with_pubkey_digests
  attr_accessor :nonce, :timestamp

  PRODUCT_NAME = 'EPICS - a ruby ebics kernel'
  PRODUCT_LANG = 'de'

  def initialize(client)
    self.client = client
    self.with_pubkey_digests = true
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
            if order_params.is_a?(String)
              xml.StandardOrderParams order_params
            elsif order_params
              xml.StandardOrderParams {
                order_params.call(xml)
              }
            end
          }
          xml.BankPubKeyDigests {
            xml.Authentication(client.bank_x.public_digest, Version: 'X002', Algorithm: 'http://www.w3.org/2001/04/xmlenc#sha256')
            xml.Encryption(client.bank_e.public_digest, Version: 'E002', Algorithm: 'http://www.w3.org/2001/04/xmlenc#sha256')
          } if with_pubkey_digests
          xml.SecurityMedium '0000'
          xml.NumSegments num_segment if num_segment
        }
        if mutable.is_a?(String)
          xml.mutable mutable
        else
          xml.mutable {
            xml.TransactionPhase 'Initialisation'
          }
        end
      }
    end.doc.root
  end
end
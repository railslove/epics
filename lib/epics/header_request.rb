class Epics::HeaderRequest
  extend Forwardable
  attr_accessor :client

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
          xml.Product(client.product_name, 'Language' => client.locale)
          xml.OrderDetails {
            build_order_details(xml, options)
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

  # EBICS 3.0 (H005) uses AdminOrderType plus a BTF Service structure, and drops
  # OrderAttribute. EBICS 2.5 (H004) keeps the classic OrderType/OrderAttribute
  # shape. The version branch is the only structural divergence in the header.
  def build_order_details(xml, options)
    if client.h005?
      build_h005_order_details(xml, options)
    else
      build_h004_order_details(xml, options)
    end
  end

  def build_h004_order_details(xml, options)
    xml.OrderType options[:order_type]
    xml.OrderAttribute options[:order_attribute]
    xml.StandardOrderParams {
      build_attributes(xml, options[:order_params])
    } if options[:order_params]
    build_attributes(xml, options[:custom_order_params]) if options[:custom_order_params]
  end

  def build_h005_order_details(xml, options)
    admin_order_type = options[:admin_order_type] || options[:order_type]
    xml.AdminOrderType admin_order_type

    case admin_order_type
    when 'BTU'
      xml.BTUOrderParams {
        build_service(xml, options[:service])
        # SignatureFlag is an empty element (H005). Its *presence* means the
        # order carries an electronic signature and is authorised within EBICS;
        # omitting it means the order is authorised outside EBICS. The optional
        # requestEDS attribute spools the order into the distributed signature
        # (EDS/VEU) queue.
        if options.fetch(:signature_flag, true)
          attrs = options[:request_eds] ? { 'requestEDS' => 'true' } : {}
          xml.SignatureFlag(attrs)
        end
        build_parameters(xml, options[:parameters])
      }
    when 'BTD'
      xml.BTDOrderParams {
        build_service(xml, options[:service])
        build_date_range(xml, options)
        build_parameters(xml, options[:parameters])
      }
    else
      # Other admin order types retrieved via ebicsRequest (HTD, HAA, HKD, HPD,
      # HAC, ...) require a StandardOrderParams element. INI/HIA/HPB use the
      # unsecured / no-pub-key request schemas whose OrderDetails carry only the
      # AdminOrderType, so they suppress it via with_order_params: false.
      if options.fetch(:with_order_params, true)
        xml.StandardOrderParams {
          build_date_range(xml, options)
        }
      end
    end
  end

  # Builds the BTF <Service> element. The child element order follows the H005
  # schema sequence: ServiceName, Scope, ServiceOption, Container, MsgName.
  def build_service(xml, service)
    return if service.nil?
    service = service.to_h if service.respond_to?(:to_h)

    xml.Service {
      xml.ServiceName service[:service_name] || service[:ServiceName]
      scope = service[:scope] || service[:Scope]
      xml.Scope scope if scope
      option = service[:service_option] || service[:ServiceOption]
      xml.ServiceOption option if option

      container = service[:container] || service[:Container]
      if container
        xml.Container('containerType' => container)
      end

      msg = service[:msg_name] || service[:MsgName] || {}
      msg = { name: msg } unless msg.is_a?(Hash)
      msg_attrs = {}
      msg_attrs['version'] = msg[:version] if msg[:version]
      msg_attrs['variant'] = msg[:variant] if msg[:variant]
      msg_attrs['format']  = msg[:format]  if msg[:format]
      xml.MsgName(msg[:name] || msg[:value], msg_attrs)
    }
  end

  def build_date_range(xml, options)
    if options[:from] && options[:to]
      xml.DateRange {
        xml.Start options[:from]
        xml.End options[:to]
      }
    end
  end

  def build_parameters(xml, parameters)
    return if parameters.nil?
    parameters.each do |name, value|
      xml.Parameter {
        xml.Name name
        xml.Value(value, 'Type' => 'string')
      }
    end
  end

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

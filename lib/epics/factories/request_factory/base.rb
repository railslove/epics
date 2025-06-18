class Epics::Factories::RequestFactory::Base
  ORDER_TYPES = %w[
    azv b2b btd btu bka
    c2s c5n c52 c53 c54 ccs cct cd1 cdb cdd cds cdz cip crz
    fdl ful h3k haa hac hev hia hkd hpb hpd htd ini ptk spr sta
    vmk wss xct xds xe2 xe3 xek z52 z53 z54 zsr
  ].freeze

  (ORDER_TYPES - %w[fdl ful h3k haa hac hev hia hkd hpb hpd htd ini ptk spr]).each do |type|
    define_method("create_#{type}") { |*| raise NotImplementedError }
  end

  def initialize(client)
    @client = client
  end

  def add_order_type(order_details_builder, order_type, with_es = false)
    raise NotImplementedError
  end

  def create_hev
    request_builder.add_container_hev do |xml_builder|
      xml_builder.add_host_id @client.host_id
    end
  end

  def create_ini(order_data)
    request_builder.add_container_unsecured do |xml_builder|
      xml_builder.add_header do |header_builder|
        header_builder.add_static do |static_builder|
          static_builder.add_host_id @client.host_id
          static_builder.add_partner_id @client.partner_id
          static_builder.add_user_id @client.user_id
          static_builder.add_product @client.product_name, @client.locale
          static_builder.add_order_details do |order_details_builder|
            add_order_type(order_details_builder, 'INI')
          end
          static_builder.add_security_medium Epics::Builders::StaticBuilder::SECURITY_MEDIUM_0000
        end
        header_builder.add_mutable
      end
      xml_builder.add_body do |body_builder|
        body_builder.add_data_transfer do |data_transfer_builder|
          data_transfer_builder.add_order_data order_data
        end
      end
    end
  end

  def create_hia(order_data)
    request_builder.add_container_unsecured do |xml_builder|
      xml_builder.add_header do |header_builder|
        header_builder.add_static do |static_builder|
          static_builder.add_host_id @client.host_id
          static_builder.add_partner_id @client.partner_id
          static_builder.add_user_id @client.user_id
          static_builder.add_product @client.product_name, @client.locale
          static_builder.add_order_details do |order_details_builder|
            add_order_type(order_details_builder, 'HIA')
          end
          static_builder.add_security_medium Epics::Builders::StaticBuilder::SECURITY_MEDIUM_0000
        end
        header_builder.add_mutable
      end
      xml_builder.add_body do |body_builder|
        body_builder.add_data_transfer do |data_transfer_builder|
          data_transfer_builder.add_order_data order_data
        end
      end
    end
  end

  def create_h3k(*, **)
    raise NotImplementedError
  end

  def create_hpb
    auth_signature_handler = Epics::Handlers::AuthSignatureHandler.new(@client.keyring)
    request_builder.add_container_secured_no_pubkey_digests do |xml_builder|
      xml_builder.add_header do |header_builder|
        header_builder.add_static do |static_builder|
          static_builder.add_host_id @client.host_id
          static_builder.add_random_nonce
          static_builder.add_timestamp Time.now.utc
          static_builder.add_partner_id @client.partner_id
          static_builder.add_user_id @client.user_id
          static_builder.add_product @client.product_name, @client.locale
          static_builder.add_order_details do |order_details_builder|
            add_order_type(order_details_builder, 'HPB')
          end
          static_builder.add_security_medium Epics::Builders::StaticBuilder::SECURITY_MEDIUM_0000
        end
        header_builder.add_mutable
      end
      xml_builder.add_body
      auth_signature_handler.handle(xml_builder)
    end
  end

  def create_spr(*, **)
    raise NotImplementedError
  end

  def create_hpd
    build_standard_request('HPD')
  end

  def create_hkd
    build_standard_request('HKD')
  end

  def create_htd
    build_standard_request('HTD')
  end

  def create_haa
    build_standard_request('HAA')
  end

  def create_hac(start_date, end_date)
    build_standard_request('HAC', start_date:, end_date:)
  end

  def create_ptk(start_date, end_date)
    build_standard_request('PTK', start_date:, end_date:)
  end

  def create_fdl(format, start_date, end_date)
    build_standard_request('FDL') do |order_details_builder|
      order_details_builder.add_fdl_order_params(format, start_date, end_date)
    end
  end

  def create_ful(*, **)
    raise NotImplementedError
  end

  def create_transfer_receipt(transaction_id, acknowledged)
    auth_signature_handler = Epics::Handlers::AuthSignatureHandler.new(@client.keyring)
    request_builder.add_container_secured do |xml_builder|
      xml_builder.add_header do |header_builder|
        header_builder.add_static do |static_builder|
          static_builder.add_host_id @client.host_id
          static_builder.add_transaction_id transaction_id
        end
        header_builder.add_mutable do |mutable_builder|
          mutable_builder.add_transaction_phase Epics::Builders::MutableBuilder::PHASE_RECEIPT
        end
      end
      xml_builder.add_body do |body_builder|
        body_builder.add_transfer_receipt do |transfer_receipt_builder|
          transfer_receipt_builder.add_receipt_code acknowledged
        end
      end
      auth_signature_handler.handle(xml_builder)
    end
  end

  def create_transfer_upload(transaction_id, transaction_key, order_data, segment_number, is_last_segment = false)
    auth_signature_handler = Epics::Handlers::AuthSignatureHandler.new(@client.keyring)
    request_builder.add_container_secured do |xml_builder|
      xml_builder.add_header do |header_builder|
        header_builder.add_static do |static_builder|
          static_builder.add_host_id @client.host_id
          static_builder.add_transaction_id transaction_id
        end
        header_builder.add_mutable do |mutable_builder|
          mutable_builder.add_transaction_phase Epics::Builders::MutableBuilder::PHASE_TRANSFER
          mutable_builder.add_segment_number segment_number, is_last_segment
        end
      end
      xml_builder.add_body do |body_builder|
        body_builder.add_data_transfer do |data_transfer_builder|
          data_transfer_builder.add_order_data(order_data, transaction_key)
        end if order_data
      end
      auth_signature_handler.handle(xml_builder)
    end
  end

  def create_transfer_download(transaction_id, segment_number, is_last_segment = false)
    create_transfer_upload(transaction_id, nil, nil, segment_number, is_last_segment)
  end

  protected

  def xml_builder
    raise NotImplementedError
  end

  def request_builder
    Epics::Builders::RequestBuilder.new(xml_builder)
  end

  private

  def build_standard_request(order_type, start_date: nil, end_date: nil, with_es: false)
    auth_signature_handler = Epics::Handlers::AuthSignatureHandler.new(@client.keyring)
    request_builder.add_container_secured do |xml_builder|
      xml_builder.add_header do |header_builder|
        header_builder.add_static do |static_builder|
          static_builder.add_host_id @client.host_id
          static_builder.add_random_nonce
          static_builder.add_timestamp Time.now.utc
          static_builder.add_partner_id @client.partner_id
          static_builder.add_user_id @client.user_id
          static_builder.add_product @client.product_name, @client.locale
          static_builder.add_order_details do |order_details_builder|
            add_order_type(order_details_builder, order_type, with_es)
            if block_given?
              yield order_details_builder
            else
              order_details_builder.add_standard_order_params start_date, end_date
            end
          end
          static_builder.add_bank_pubbey_digests(
            @client.keyring.bank_authentication.version,
            @digest_resolver.sign_digest(@client.keyring.bank_authentication),
            @client.keyring.bank_encryption.version,
            @digest_resolver.sign_digest(@client.keyring.bank_encryption)
          )
          static_builder.add_security_medium Epics::Builders::StaticBuilder::SECURITY_MEDIUM_0000
        end
        header_builder.add_mutable do |mutable_builder|
          mutable_builder.add_transaction_phase Epics::Builders::MutableBuilder::PHASE_INITIALIZATION
        end
      end
      xml_builder.add_body
      auth_signature_handler.handle(xml_builder)
    end
  end
end

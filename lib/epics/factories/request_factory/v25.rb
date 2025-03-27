class Epics::Factories::RequestFactory::V25 < Epics::Factories::RequestFactory::V2
  NOT_IMPLEMENTED_ORDER_TYPES = %w[
    xek zsr
  ].freeze

  NOT_IMPLEMENTED_ORDER_TYPES.each do |type|
    define_method("create_#{type}") { |*| raise NotImplementedError }
  end

  def create_bka(start_date, end_date)
    build_download_request('BKA', start_date:, end_date:)
  end

  def create_c52(start_date, end_date)
    build_download_request('C52', start_date:, end_date:)
  end

  def create_c53(start_date, end_date)
    build_download_request('C53', start_date:, end_date:)
  end

  def create_c54(start_date, end_date)
    build_download_request('C54', start_date:, end_date:)
  end

  def create_c5n(start_date, end_date)
    build_download_request('C5N', start_date:, end_date:)
  end

  def create_cdz(start_date, end_date)
    build_download_request('CDZ', start_date:, end_date:)
  end

  def create_crz(start_date, end_date)
    build_download_request('CRZ', start_date:, end_date:)
  end

  def create_sta(start_date, end_date)
    build_download_request('STA', start_date:, end_date:)
  end

  def create_vmk(start_date, end_date)
    build_download_request('VMK', start_date:, end_date:)
  end

  def create_wss
    build_download_request('WSS')
  end

  def create_z52(start_date, end_date)
    build_download_request('Z52', start_date:, end_date:)
  end

  def create_z53(start_date, end_date)
    build_download_request('Z53', start_date:, end_date:)
  end

  def create_z54(start_date, end_date)
    build_download_request('Z54', start_date:, end_date:)
  end

  def create_b2b(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('B2B', transaction_key, signature_data, 1, true)
  end

  def create_c2s(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('C2S', transaction_key, signature_data, 1, false)
  end

  def create_ccs(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('CCS', transaction_key, signature_data, 1, false)
  end

  def create_cct(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('CCT', transaction_key, signature_data, 1, true)
  end

  def create_cds(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('CDS', transaction_key, signature_data, 1, false)
  end

  def create_cd1(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('CD1', transaction_key, signature_data, 1, true)
  end

  def create_cdd(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('CDD', transaction_key, signature_data, 1, true)
  end

  def create_cdb(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('CDB', transaction_key, signature_data, 1, true)
  end

  def create_cip(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('CIP', transaction_key, signature_data, 1, true)
  end

  def create_xds(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('XDS', transaction_key, signature_data, 1, true)
  end

  def create_xe2(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('XE2', transaction_key, signature_data, 1, true)
  end

  def create_xe3(digest, transaction_key)
    signature_data = @user_signature_handle.handle(digest).to_xml
    build_upload_request('XE3', transaction_key, signature_data, 1, true)
  end

  private

  def build_download_request(order_type, start_date: nil, end_date: nil, &)
    build_standard_request(order_type, start_date: start_date, end_date: end_date, &)
  end

  def build_upload_request(order_type, transaction_key, signature_data, num_segments, with_es = false)
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
            order_details_builder.add_standard_order_params
          end
          static_builder.add_bank_pubbey_digests(
            @client.keyring.bank_authentication.version,
            @digest_resolver.sign_digest(@client.keyring.bank_authentication.key),
            @client.keyring.bank_encryption.version,
            @digest_resolver.sign_digest(@client.keyring.bank_encryption.key)
          )
          static_builder.add_security_medium Epics::Builders::StaticBuilder::SECURITY_MEDIUM_0000
          static_builder.add_num_segments num_segments
        end
        header_builder.add_mutable do |mutable_builder|
          mutable_builder.add_transaction_phase Epics::Builders::MutableBuilder::PHASE_INITIALIZATION
        end
      end
      xml_builder.add_body do |body_builder|
        body_builder.add_data_transfer do |data_transfer_builder|
          data_transfer_builder.add_data_encryption_info do |data_encryption_info_builder|
            data_encryption_info_builder.add_encryption_pubkey_digest @client.keyring
            data_encryption_info_builder.add_transaction_key transaction_key, @client.keyring
          end
          data_transfer_builder.add_signature_data signature_data, transaction_key
        end
      end
      auth_signature_handler.handle(xml_builder)
    end
  end

  protected

  def xml_builder
    Epics::Builders::XmlBuilder::V25.new
  end

  def add_order_type(order_details_builder, order_type, with_es = false)
    order_attribute = case order_type
    when 'INI', 'HIA'
      Epics::Builders::OrderDetailsBuilder::ORDER_ATTRIBUTE_DZNNN
    else
      if with_es
        Epics::Builders::OrderDetailsBuilder::ORDER_ATTRIBUTE_OZHNN
      else
        Epics::Builders::OrderDetailsBuilder::ORDER_ATTRIBUTE_DZHNN
      end
    end

    order_details_builder.add_order_type order_type
    order_details_builder.add_order_attribute order_attribute
  end
end

class Epics::Factories::RequestFactory::V3 < Epics::Factories::RequestFactory::Base
  def initialize(client)
    @digest_resolver = Epics::Services::DigestResolver::V3.new
    @user_signature_handle = Epics::Handlers::UserSignatureHandler::V3.new(client)
    @crypt_service = Epics::Services::CryptService.new
    super
  end

  def create_btd(options = {})
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
            add_order_type(order_details_builder, 'BTD')
            order_details_builder.add_btd_order_params **options
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
    end
  end

  def create_btu(transaction_key, digest, num_segments, options = {})
    signature_data = @user_signature_handle.handle(digest).to_xml
    data_digest = @crypt_service.sign(@client.keyring.user_signature, digest)
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
            add_order_type(order_details_builder, 'BTU')
            order_details_builder.add_btu_order_params **options
          end
          static_builder.add_bank_pubbey_digests(
            @client.keyring.bank_authentication.version,
            @digest_resolver.sign_digest(@client.keyring.bank_authentication),
            @client.keyring.bank_encryption.version,
            @digest_resolver.sign_digest(@client.keyring.bank_encryption)
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
          data_transfer_builder.add_data_digest @client.keyring.user_signature.version, data_digest
          data_transfer_builder.add_additional_order_info
        end
      end
      auth_signature_handler.handle(xml_builder)
    end
  end

  def create_c52(start_date, end_date)
    create_btd(service_name: 'STM', msg_name: 'camt.052', start_date:, end_date:)
  end

  def create_c53(start_date, end_date)
    create_btd(service_name: 'EOP', msg_name: 'camt.053', container_type: 'ZIP', start_date:, end_date:)
  end

  def create_c54(start_date, end_date)
    create_btd(service_name: 'REP', msg_name: 'camt.054', container_type: 'ZIP', start_date:, end_date:)
  end

  def create_sta(start_date, end_date)
    create_btd(service_name: 'EOP', msg_name: 'mt940', start_date:, end_date:)
  end

  def create_vmk(start_date, end_date)
    create_btd(service_name: 'STM', msg_name: 'mt942', start_date:, end_date:)
  end

  def create_z52(start_date, end_date)
    create_btd(service_name: 'STM', msg_name: 'camt.052', container_type: 'ZIP', start_date:, end_date:)
  end

  def create_z53(start_date, end_date)
    create_btd(service_name: 'EOP', msg_name: 'camt.053', container_type: 'ZIP', start_date:, end_date:)
  end

  def create_z54(start_date, end_date)
    create_btd(service_name: 'EOP', msg_name: 'camt.054', container_type: 'ZIP', service_option: 'XQRR', start_date:, end_date:)
  end

  def create_xek(start_date, end_date)
    create_btd(service_name: 'EOP', msg_name: 'pdf', container_type: 'ZIP', start_date:, end_date:)
  end

  def create_zsr(start_date, end_date)
    create_btd(service_name: 'PSR', scope: 'BIL', msg_name: 'pain.002', container_type: 'ZIP', start_date:, end_date:)
  end

  def create_cct(digest, transaction_key)
    create_btu(transaction_key, digest, 1, service_name: 'SCT', msg_name: 'pain.001', filename: 'cct.pain.001.xxx.xml')
  end

  def create_cdd(digest, transaction_key)
    create_btu(transaction_key, digest, 1, service_name: 'SDD', scope: 'GLB', msg_name: 'pain.008', service_option: 'COR', filename: 'cdd.pain.008.xxx.xml')
  end

  def create_cdb(digest, transaction_key)
    create_btu(transaction_key, digest, 1, service_name: 'SDD', msg_name: 'pain.008', service_option: 'B2B', filename: 'cdb.pain.008.xxx.xml')
  end

  def create_cip(digest, transaction_key)
    create_btu(transaction_key, digest, 1, service_name: 'SCI', msg_name: 'pain.001', filename: 'cip.pain.001.xxx.xml')
  end

  def create_xe2(digest, transaction_key)
    create_btu(transaction_key, digest, 1, service_name: 'MCT', msg_name: 'pain.001', filename: 'xe2.pain.001.xxx.xml')
  end

  def create_xe3(digest, transaction_key)
    create_btu(transaction_key, digest, 1, service_name: 'SDD', msg_name: 'pain.008', filename: 'xe3.pain.008.xxx.xml')
  end

  def create_yct(digest, transaction_key)
    create_btu(transaction_key, digest, 1, service_name: 'MCT', scope: 'BIL', msg_name: 'pain.001', filename: 'yct.pain.001.xxx.xml')
  end

  protected

  def xml_builder
    Epics::Builders::XmlBuilder::V3.new
  end

  def add_order_type(order_details_builder, order_type, with_es = false)
    order_details_builder.add_admin_order_type order_type
  end
end

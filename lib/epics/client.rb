class Epics::Client
  extend Forwardable

  attr_accessor :passphrase, :url, :host_id, :user_id, :partner_id, :keys_content, :locale, :product_name, :current_order_id,
                :debug_mode
  attr_reader :keyring
  attr_writer :iban, :bic, :name

  def_delegators :connection, :post

  USER_AGENT = "EPICS v#{Epics::VERSION}"

  def initialize(keys_content, passphrase, url, host_id, user_id, partner_id, options = {})
    self.url = url
    self.host_id    = host_id
    self.user_id    = user_id
    self.partner_id = partner_id
    self.locale = options[:locale] || Epics::DEFAULT_LOCALE
    self.product_name = options[:product_name] || Epics::DEFAULT_PRODUCT_NAME
    self.current_order_id = options[:order_id] || 466_560
    @keyring = Epics::Keyring.new(options[:version] || Epics::Keyring::VERSION_25)
    self.keys_content = keys_content.respond_to?(:read) ? keys_content.read : keys_content if keys_content
    self.passphrase = passphrase
    self.debug_mode = !!options[:debug_mode]
    extract_keys if keys_content
    keyring.user_signature&.certificate = parse_certificate(options[:x_509_certificate_a_content])
    keyring.user_authentication&.certificate = parse_certificate(options[:x_509_certificate_x_content])
    keyring.user_encryption&.certificate = parse_certificate(options[:x_509_certificate_e_content])

    yield self if block_given?
  end

  def version
    keyring.version
  end

  def urn_schema
    case version
    when Epics::Keyring::VERSION_24
      "http://www.ebics.org/#{version}"
    when Epics::Keyring::VERSION_25, Epics::Keyring::VERSION_30
      "urn:org:ebics:#{version}"
    end
  end

  def inspect
    "#<#{self.class}:#{object_id}
     @version=#{keyring.version},
     @keys=#{keys.keys},
     @user_id=\"#{user_id}\",
     @partner_id=\"#{partner_id}\""
  end

  def next_order_id
    raise 'Order ID overflow' if current_order_id >= 1_679_615

    self.current_order_id += 1
  end

  def encryption_version
    keyring.user_encryption&.version
  end

  def encryption_key
    keyring.user_encryption&.key
  end

  def signature_version
    keyring.user_signature&.version
  end

  def signature_key
    keyring.user_signature&.key
  end

  def authentication_version
    keyring.user_authentication&.version
  end

  def authentication_key
    keyring.user_authentication&.key
  end

  def bank_encryption_key
    keyring.bank_encryption&.key
  end

  def bank_encryption_version
    keyring.bank_encryption&.version
  end

  def bank_authentication_key
    keyring.bank_authentication&.key
  end

  def bank_authentication_version
    keyring.bank_authentication&.version
  end

  def keys
    user_signature = [keyring.user_signature, keyring.user_authentication,
                      keyring.user_encryption].each_with_object({}) do |signature, keys|
      keys[signature.version] = signature.key if signature
    end
    bank_signature = [keyring.bank_authentication, keyring.bank_encryption].each_with_object({}) do |signature, keys|
      keys["#{host_id.upcase}.#{signature.version}"] = signature.key if signature
    end

    user_signature.merge(bank_signature)
  end

  def name
    @name ||= begin
      self.HTD
      @name
    end
  end

  def iban
    @iban ||= begin
      self.HTD
      @iban
    end
  end

  def bic
    @bic ||= begin
      self.HTD
      @bic
    end
  end

  def order_types
    @order_types ||= begin
      self.HTD
      @order_types
    end
  end

  def self.setup(passphrase, url, host_id, user_id, partner_id, keysize = 2048, options = {}, &block)
    signature_version = options.delete(:signature_version) || Epics::Signature::A_VERSION_6
    client = new(nil, passphrase, url, host_id, user_id, partner_id, options, &block)
    [signature_version, Epics::Signature::X_VERSION_2, Epics::Signature::E_VERSION_2].each do |version|
      signature = case version
                  when Epics::Signature::A_VERSION_6
                    Epics::Signature.new(version, Epics::SignatureAlgorithm::RsaPss.new(OpenSSL::PKey::RSA.generate(keysize)))
                  when Epics::Signature::A_VERSION_5, Epics::Signature::X_VERSION_2, Epics::Signature::E_VERSION_2
                    Epics::Signature.new(version, Epics::SignatureAlgorithm::RsaPkcs1.new(OpenSSL::PKey::RSA.generate(keysize)))
                  end

      case signature.type
      when Epics::Signature::TYPE_A
        client.keyring.user_signature = signature
      when Epics::Signature::TYPE_X
        client.keyring.user_authentication = signature
      when Epics::Signature::TYPE_E
        client.keyring.user_encryption = signature
      end
    end

    client
  end

  def letter_renderer
    @letter_renderer ||= Epics::LetterRenderer.new(self)
  end

  def ini_letter(bankname)
    letter_renderer.render(bankname)
  end

  def save_ini_letter(bankname, path)
    File.write(path, ini_letter(bankname))
    path
  end

  def credit(document)
    self.CCT(document)
  end

  def debit(document, type = :CDD)
    public_send(type, document)
  end

  def statements(from, to, type = :STA)
    public_send(type, from: from, to: to)
  end

  def HIA
    post(url, Epics::HIA.new(self).to_xml).body.ok?
  end

  def INI
    post(url, Epics::INI.new(self).to_xml).body.ok?
  end

  def HEV
    res = post(url, Epics::HEV.new(self).to_xml).body
    res.doc.xpath('//xmlns:VersionNumber', xmlns: 'http://www.ebics.org/H000').each_with_object({}) do |node, versions|
      versions[node['ProtocolVersion']] = node.content
    end
  end

  def HPB
    response_xml = download(Epics::HPB)
    doc = Nokogiri::XML(response_xml)

    doc.xpath('//xmlns:PubKeyValue', xmlns: urn_schema).each do |node|
      signature_version = node.parent.last_element_child.content

      modulus  = Base64.decode64(node.at_xpath(".//*[local-name() = 'Modulus']").content)
      exponent = Base64.decode64(node.at_xpath(".//*[local-name() = 'Exponent']").content)

      sequence = []
      sequence << OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(modulus, 2))
      sequence << OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(exponent, 2))

      bank = OpenSSL::PKey::RSA.new(OpenSSL::ASN1::Sequence(sequence).to_der)
      signature = Epics::Signature.new(
        signature_version,
        case signature_version
        when Epics::Signature::E_VERSION_2, Epics::Signature::X_VERSION_2
          Epics::SignatureAlgorithm::RsaPkcs1.new(bank)
        end
      )

      case signature.type
      when Epics::Signature::TYPE_E
        keyring.bank_encryption = signature
      when Epics::Signature::TYPE_X
        keyring.bank_authentication = signature
      end
    rescue Epics::Signature::UnknownTypeError
    rescue Epics::Signature::UnknownVersionError
    end

    doc.xpath('//ds:X509Certificate', xmlns: urn_schema,
                                      ds: 'http://www.w3.org/2000/09/xmldsig#').each do |cert_node|
      cert_pem = "-----BEGIN CERTIFICATE-----\n#{cert_node.content}\n-----END CERTIFICATE-----"
      cert = OpenSSL::X509::Certificate.new(cert_pem)

      info_element = cert_node.parent&.parent
      auth_version = info_element&.at_xpath('.//*[local-name() = "AuthenticationVersion"]')&.content
      enc_version = info_element&.at_xpath('.//*[local-name() = "EncryptionVersion"]')&.content
      version = auth_version || enc_version

      next unless version

      begin
        signature = Epics::Signature.new(
          version,
          Epics::SignatureAlgorithm::RsaPkcs1.new(cert.public_key)
        )
        signature.certificate = Epics::Crypt::X509.new(cert_pem)

        case signature.type
        when Epics::Signature::TYPE_E
          keyring.bank_encryption = signature
        when Epics::Signature::TYPE_X
          keyring.bank_authentication = signature
        end
      rescue Epics::Signature::UnknownTypeError
      rescue Epics::Signature::UnknownVersionError
      end
    end

    [bank_authentication_key, bank_encryption_key]
  end

  def AZV(document, **options)
    upload(Epics::AZV, document, **options)
  end

  def CD1(document, **options)
    upload(Epics::CD1, document, **options)
  end

  def CDB(document, **options)
    upload(Epics::CDB, document, **options)
  end

  def C2S(document, **options)
    upload(Epics::C2S, document, **options)
  end

  def CDD(document, **options)
    upload(Epics::CDD, document, **options)
  end

  def XE2(document, **options)
    upload(Epics::XE2, document, **options)
  end

  def XE3(document, **options)
    upload(Epics::XE3, document, **options)
  end

  def CDS(document, **options)
    upload(Epics::CDS, document, **options)
  end

  def XDS(document, **options)
    upload(Epics::XDS, document, **options)
  end

  def CCT(document, **options)
    upload(Epics::CCT, document, **options)
  end

  def CIP(document, **options)
    upload(Epics::CIP, document, **options)
  end

  def CCS(document, **options)
    upload(Epics::CCS, document, **options)
  end

  def XCT(document, **options)
    upload(Epics::XCT, document, **options)
  end

  def FUL(document, **options)
    upload(Epics::FUL, document, **options)
  end

  def STA(from = nil, to = nil)
    download(Epics::STA, from: from, to: to)
  end

  def FDL(format, from = nil, to = nil)
    download(Epics::FDL, file_format: format, from: from, to: to)
  end

  def VMK(from = nil, to = nil)
    download(Epics::VMK, from: from, to: to)
  end

  def CDZ(from = nil, to = nil)
    download_and_unzip(Epics::CDZ, from: from, to: to)
  end

  def CRZ(from = nil, to = nil)
    download_and_unzip(Epics::CRZ, from: from, to: to)
  end

  def BKA(from, to)
    download_and_unzip(Epics::BKA, from: from, to: to)
  end

  def C52(from, to)
    download_and_unzip(Epics::C52, from: from, to: to)
  end

  def C53(from, to)
    download_and_unzip(Epics::C53, from: from, to: to)
  end

  def C54(from, to)
    download_and_unzip(Epics::C54, from: from, to: to)
  end

  def C5N(from, to)
    download_and_unzip(Epics::C5N, from: from, to: to)
  end

  def Z01(from, to)
    download_and_unzip(Epics::Z01, from: from, to: to)
  end

  def Z52(from, to)
    download_and_unzip(Epics::Z52, from: from, to: to)
  end

  def Z53(from, to)
    download_and_unzip(Epics::Z53, from: from, to: to)
  end

  def Z54(from, to)
    download_and_unzip(Epics::Z54, from: from, to: to)
  end

  def HAA
    doc = Nokogiri::XML(download(Epics::HAA))
    ns = { xmlns: urn_schema }

    case version
    when Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25
      doc.at_xpath('//xmlns:OrderTypes', ns).content.split(/\s/)
    when Epics::Keyring::VERSION_30
      doc.xpath('//xmlns:Service', ns).map do |service|
        {
          service_name: service.at_xpath('xmlns:ServiceName', ns)&.text,
          scope: service.at_xpath('xmlns:Scope', ns)&.text,
          service_option: service.at_xpath('xmlns:ServiceOption', ns)&.text,
          container: service.at_xpath('xmlns:Container', ns)&.[]('containerType'),
          msg_name: service.at_xpath('xmlns:MsgName', ns)&.text
        }.compact
      end
    end
  end

  def HTD
    Nokogiri::XML(download(Epics::HTD)).tap do |htd|
      @iban ||= begin
        htd.at_xpath("//xmlns:AccountNumber[@international='true']", xmlns: urn_schema).text
      rescue StandardError
        nil
      end
      @bic ||= begin
        htd.at_xpath("//xmlns:BankCode[@international='true']", xmlns: urn_schema).text
      rescue StandardError
        nil
      end
      @name ||= begin
        htd.at_xpath('//xmlns:Name', xmlns: urn_schema).text
      rescue StandardError
        nil
      end
      @order_types ||= case version
                       when Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25
                         htd.search('//xmlns:OrderTypes', xmlns: urn_schema).map do |o|
                           o.content.split(/\s/)
                         end.delete_if { |o| o == '' }.flatten
                       when Epics::Keyring::VERSION_30
                         htd.xpath('//xmlns:Service', xmlns: urn_schema).map do |service|
                           ns = { xmlns: urn_schema }
                           {
                             service_name: service.at_xpath('xmlns:ServiceName', ns)&.text,
                             scope: service.at_xpath('xmlns:Scope', ns)&.text,
                             service_option: service.at_xpath('xmlns:ServiceOption', ns)&.text,
                             container: service.at_xpath('xmlns:Container', ns)&.[]('containerType'),
                             msg_name: service.at_xpath('xmlns:MsgName', ns)&.text
                           }.compact
                         end
                       end
    end.to_xml
  end

  def HPD
    download(Epics::HPD)
  end

  def HKD
    download(Epics::HKD)
  end

  def PTK(from, to)
    download(Epics::PTK, from: from, to: to)
  end

  def HAC(from = nil, to = nil)
    download(Epics::HAC, from: from, to: to)
  end

  def WSS
    download(Epics::WSS)
  end

  def save_keys(path)
    File.write(path, dump_keys)
  end

  private

  def parse_certificate(content)
    return if content.nil? || content.empty?

    Epics::Crypt::X509.new(content)
  rescue OpenSSL::X509::CertificateError
  end

  def upload(order_type, document, **options)
    order = order_type.new(self, document, **options)
    session = post(url, order.to_xml).body
    order.transaction_id = session.transaction_id

    res = post(url, order.to_transfer_xml).body

    [res.transaction_id, [res.order_id, session.order_id].detect { |id| id.to_s.chars.any? }]
  end

  def download(order_type, *args, **options)
    document = order_type.new(self, *args, **options)
    res = post(url, document.to_xml).body
    document.transaction_id = res.transaction_id

    post(url, document.to_receipt_xml).body if res.segmented? && res.last_segment?

    res.order_data
  end

  def download_and_unzip(order_type, *args, **options)
    [].tap do |entries|
      Zip::File.open_buffer(StringIO.new(download(order_type, *args, **options))).each do |zipfile|
        entries << zipfile.get_input_stream.read
      end
    end
  end

  def connection
    @connection ||= Faraday.new(headers: { 'Content-Type' => 'text/xml', user_agent: USER_AGENT },
                                ssl: { verify: verify_ssl? }) do |faraday|
      faraday.use Epics::ParseEbics, { client: self }
      # faraday.use MyAdapter
      faraday.response :logger, ::Logger.new(STDOUT), bodies: true if debug_mode # log requests/response to STDOUT
    end
  end

  def extract_keys
    JSON.load(keys_content).each do |signature_version, value|
      next unless value

      # Handle new format: { "key" => "...", "cert" => "..." }
      if value.is_a?(Hash)
        key_pem = decrypt(value['key'])
        cert_pem = value['cert'] ? decrypt(value['cert']) : nil
      else
        key_pem = decrypt(value)
        cert_pem = nil
      end

      is_bank_key = signature_version.start_with?("#{host_id.upcase}.")
      signature_version = signature_version.sub("#{host_id.upcase}.", '') if is_bank_key

      signature = Epics::Signature.new(
        signature_version,
        case signature_version
        when Epics::Signature::A_VERSION_6
          Epics::SignatureAlgorithm::RsaPss.new(key_pem)
        when Epics::Signature::A_VERSION_5, Epics::Signature::E_VERSION_2, Epics::Signature::X_VERSION_2
          Epics::SignatureAlgorithm::RsaPkcs1.new(key_pem)
        end
      )

      signature.certificate = Epics::Crypt::X509.new(cert_pem) if cert_pem

      if is_bank_key
        case signature.type
        when Epics::Signature::TYPE_X
          keyring.bank_authentication = signature
        when Epics::Signature::TYPE_E
          keyring.bank_encryption = signature
        end
      else
        case signature.type
        when Epics::Signature::TYPE_A
          keyring.user_signature = signature
        when Epics::Signature::TYPE_X
          keyring.user_authentication = signature
        when Epics::Signature::TYPE_E
          keyring.user_encryption = signature
        end
      end
    rescue Epics::Signature::UnknownTypeError
    rescue Epics::Signature::UnknownVersionError
    end
  end

  def dump_keys
    data = {}

    [keyring.user_signature, keyring.user_authentication,
     keyring.user_encryption].each do |sig|
      next unless sig

      data[sig.version] = encrypt(sig.key.key.to_pem)
    end

    [keyring.bank_authentication, keyring.bank_encryption].each do |sig|
      next unless sig

      key_id = "#{host_id.upcase}.#{sig.version}"
      data[key_id] = if sig.certificate
                       { 'key' => encrypt(sig.key.key.to_pem), 'cert' => encrypt(sig.certificate.to_pem) }
                     else
                       encrypt(sig.key.key.to_pem)
                     end
    end

    JSON.pretty_generate(data, JSON.dump_default_options)
  end

  def new_cipher
    # Re-using the cipher between keys has weird behaviours with openssl3
    # Using a fresh key instead of memoizing it on the client simplifies things
    OpenSSL::Cipher.new('aes-256-cbc')
  end

  def encrypt(data)
    salt = OpenSSL::Random.random_bytes(8)

    cipher = setup_cipher(:encrypt, passphrase, salt)
    Base64.strict_encode64([salt, cipher.update(data) + cipher.final].join)
  end

  def decrypt(data)
    data = Base64.strict_decode64(data)
    salt = data[0..7]
    data = data[8..-1]

    cipher = setup_cipher(:decrypt, passphrase, salt)
    cipher.update(data) + cipher.final
  end

  def setup_cipher(method, passphrase, salt)
    cipher = new_cipher
    cipher.send(method)
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(passphrase, salt, 1, cipher.key_len)
    cipher
  end

  def verify_ssl?
    ENV['EPICS_VERIFY_SSL'] != 'false'
  end
end

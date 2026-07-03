class Epics::Client
  extend Forwardable

  attr_accessor :passphrase, :url, :host_id, :user_id, :partner_id, :keys, :keys_content, :locale, :product_name,
                :x_509_certificates_content, :debug_mode, :ebics_version

  attr_writer :iban, :bic, :name
  
  def_delegators :connection, :post
  
  def initialize(keys_content, passphrase, url, host_id, user_id, partner_id, options = {})
    self.keys_content = keys_content.respond_to?(:read) ? keys_content.read : keys_content if keys_content
    self.passphrase = passphrase
    self.keys = extract_keys if keys_content
    self.url  = url
    self.host_id    = host_id
    self.user_id    = user_id
    self.partner_id = partner_id
    self.locale = options[:locale] || Epics::DEFAULT_LOCALE
    self.product_name = options[:product_name] || Epics::DEFAULT_PRODUCT_NAME
    self.debug_mode = !!options[:debug_mode]
    self.ebics_version = (options[:version] || Epics::DEFAULT_VERSION).to_s.downcase.to_sym
    unless Epics::EBICS_PROTOCOLS.key?(ebics_version)
      raise ArgumentError, "Unsupported EBICS version #{ebics_version.inspect}, expected one of #{Epics::EBICS_PROTOCOLS.keys.inspect}"
    end
    self.x_509_certificates_content = {
      a: options[:x_509_certificate_a_content],
      x: options[:x_509_certificate_x_content],
      e: options[:x_509_certificate_e_content]
    }
  end

  def protocol
    Epics::EBICS_PROTOCOLS.fetch(ebics_version)
  end

  def namespace
    protocol[:namespace]
  end

  def protocol_version
    protocol[:version]
  end

  def revision
    protocol[:revision]
  end

  def h005?
    ebics_version == :h005
  end

  def inspect
    "#<#{self.class}:#{self.object_id}
     @keys=#{self.keys.keys},
     @user_id=\"#{self.user_id}\",
     @partner_id=\"#{self.partner_id}\""
  end

  def e
    keys["E002"]
  end

  def a
    keys["A006"]
  end

  def x
    keys["X002"]
  end

  def bank_e
    keys["#{host_id.upcase}.E002"]
  end

  def bank_x
    keys["#{host_id.upcase}.X002"]
  end

  def name
    @name ||= (self.HTD; @name)
  end

  def iban
    @iban ||= (self.HTD; @iban)
  end

  def bic
    @bic ||= (self.HTD; @bic)
  end

  def order_types
    @order_types ||= (self.HTD; @order_types)
  end

  def self.setup(passphrase, url, host_id, user_id, partner_id, keysize = 2048, options = {})
    client = new(nil, passphrase, url, host_id, user_id, partner_id, options)
    client.keys = %w(A006 X002 E002).each_with_object({}) do |type, memo|
      memo[type] = Epics::Key.new( OpenSSL::PKey::RSA.generate(keysize) )
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

  def header_request
    @header_request ||= Epics::HeaderRequest.new(self)
  end

  def credit(document)
    self.CCT(document)
  end

  def debit(document, type = :CDD)
    self.public_send(type, document)
  end

  def statements(from, to, type = :STA)
    self.public_send(type, from: from, to: to)
  end

  def HIA
    post(url, Epics::HIA.new(self).to_xml).body.ok?
  end

  def INI
    post(url, Epics::INI.new(self).to_xml).body.ok?
  end

  def HEV
    res = post(url, Epics::HEV.new(self).to_xml).body
    res.doc.xpath("//xmlns:VersionNumber", xmlns: 'http://www.ebics.org/H000').each_with_object({}) do |node, versions|
      versions[node['ProtocolVersion']] = node.content
    end
  end

  def HPB
    Nokogiri::XML(download(Epics::HPB)).xpath("//xmlns:PubKeyValue", xmlns: namespace).each do |node|
      type = node.parent.last_element_child.content

      modulus  = Base64.decode64(node.at_xpath(".//*[local-name() = 'Modulus']").content)
      exponent = Base64.decode64(node.at_xpath(".//*[local-name() = 'Exponent']").content)

      sequence = []
      sequence << OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(modulus, 2))
      sequence << OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(exponent, 2))

      bank = OpenSSL::PKey::RSA.new(OpenSSL::ASN1::Sequence(sequence).to_der)

      self.keys["#{host_id.upcase}.#{type}"] = Epics::Key.new(bank)
    end

    [bank_x, bank_e]
  end

  def AZV(document)
    upload(Epics::AZV, document)
  end

  def CD1(document)
    upload(Epics::CD1, document)
  end

  def CDB(document)
    return btf_upload('CDB', document) if h005?
    upload(Epics::CDB, document)
  end

  def C2S(document)
    upload(Epics::C2S, document)
  end

  def CDD(document)
    return btf_upload('CDD', document) if h005?
    upload(Epics::CDD, document)
  end

  def XE2(document)
    upload(Epics::XE2, document)
  end

  def XE3(document)
    upload(Epics::XE3, document)
  end

  def CDS(document)
    upload(Epics::CDS, document)
  end

  def XDS(document)
    upload(Epics::XDS, document)
  end

  def CCT(document)
    return btf_upload('CCT', document) if h005?
    upload(Epics::CCT, document)
  end

  def CIP(document)
    upload(Epics::CIP, document)
  end

  def CCS(document)
    return btf_upload('CCS', document) if h005?
    upload(Epics::CCS, document)
  end

  def XCT(document)
    upload(Epics::XCT, document)
  end

  def FUL(document)
    upload(Epics::FUL, document)
  end

  # EBICS 3.0 (H005) generic upload. `service` is an Epics::BTF (or a hash with
  # the same keys). Replaces FUL under H005.
  def BTU(document, service, signature_flag: true, request_eds: false, parameters: nil)
    upload(Epics::BTU, document, service: service, signature_flag: signature_flag, request_eds: request_eds, parameters: parameters)
  end

  # EBICS 3.0 (H005) generic download. `service` is an Epics::BTF (or a hash with
  # the same keys). Replaces FDL under H005.
  def BTD(service, from: nil, to: nil, parameters: nil)
    download(Epics::BTD, service: service, from: from, to: to, parameters: parameters)
  end

  def STA(from = nil, to = nil)
    return btf_download('STA', from, to) if h005?
    download(Epics::STA, from: from, to: to)
  end

  def FDL(format, from = nil, to = nil)
    download(Epics::FDL, file_format: format, from: from, to: to )
  end

  def VMK(from = nil, to = nil)
    return btf_download('VMK', from, to) if h005?
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
    return btf_download('C52', from, to) if h005?
    download_and_unzip(Epics::C52, from: from, to: to)
  end

  def C53(from, to)
    return btf_download('C53', from, to) if h005?
    download_and_unzip(Epics::C53, from: from, to: to)
  end

  def C54(from, to)
    return btf_download('C54', from, to) if h005?
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
    Nokogiri::XML(download(Epics::HAA)).at_xpath("//xmlns:OrderTypes", xmlns: namespace).content.split(/\s/)
  end

  def HTD
    Nokogiri::XML(download(Epics::HTD)).tap do |htd|
      @iban        ||= htd.at_xpath("//xmlns:AccountNumber[@international='true']", xmlns: namespace).text rescue nil
      @bic         ||= htd.at_xpath("//xmlns:BankCode[@international='true']", xmlns: namespace).text rescue nil
      @name        ||= htd.at_xpath("//xmlns:Name", xmlns: namespace).text rescue nil
      @order_types ||= htd.search("//xmlns:OrderTypes", xmlns: namespace).map{|o| o.content.split(/\s/) }.delete_if{|o| o == ""}.flatten
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
  
  def x_509_certificate(type)
    content = x_509_certificates_content[type.to_sym]
    if content.nil? || content.empty?
      # EBICS 3.0 mandates X.509 certificates for all keys. When none was
      # supplied, fall back to a self-signed certificate (valid for shared-key
      # banks, e.g. German banks). H004 keeps the raw RSAKeyValue behaviour.
      return unless h005?
      return self_signed_certificate(type)
    end
    Epics::X509Certificate.new(content)
  end
  
  def x_509_certificate_hash(type)
    content = x_509_certificates_content[type.to_sym]
    return if content.nil? || content.empty?
    cert = OpenSSL::X509::Certificate.new(content)
    Digest::SHA256.hexdigest(cert.to_der).upcase
  end

  private

  KEY_FOR_CERT_TYPE = { a: 'A006', x: 'X002', e: 'E002' }.freeze

  def self_signed_certificate(type)
    key = keys[KEY_FOR_CERT_TYPE.fetch(type.to_sym)]
    return unless key
    @self_signed_certificates ||= {}
    @self_signed_certificates[type.to_sym] ||=
      Epics::X509Certificate.generate_self_signed(
        key.key,
        subject: "/CN=#{user_id}/O=#{partner_id}/OU=#{host_id}"
      )
  end

  # Route a classic order code to its H005 BTF Service via Epics::BtfMapping.
  def btf_upload(code, document)
    self.BTU(document, Epics::BtfMapping.upload(code))
  end

  def btf_download(code, from, to)
    btf = Epics::BtfMapping.download(code)
    if btf.container == 'ZIP'
      download_and_unzip(Epics::BTD, service: btf, from: from, to: to)
    else
      self.BTD(btf, from: from, to: to)
    end
  end

  def upload(order_type, document, **options)
    order = order_type.new(self, document, **options)
    res = post(url, order.to_xml).body
    order.transaction_id = res.transaction_id

    order_id = res.order_id

    res = post(url, order.to_transfer_xml).body

    return res.transaction_id, [res.order_id, order_id].detect { |id| id.to_s.chars.any? }
  end

  def download(order_type, *args, **options)
    document = order_type.new(self, *args, **options)
    res = post(url, document.to_xml).body
    document.transaction_id = res.transaction_id

    if res.segmented? && res.last_segment?
      post(url, document.to_receipt_xml).body
    end

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
    @connection ||= Faraday.new(headers: { 'Content-Type' => 'text/xml', user_agent: "EPICS v#{Epics::VERSION}"}, ssl: { verify: verify_ssl? }) do |faraday|
      faraday.use Epics::XMLSIG, { client: self }
      faraday.use Epics::ParseEbics, { client: self}
      # faraday.use MyAdapter
      faraday.response :logger, ::Logger.new(STDOUT), bodies: true if debug_mode # log requests/response to STDOUT
    end
  end

  def extract_keys
    JSON.load(self.keys_content).each_with_object({}) do |(type, key), memo|
      memo[type] = Epics::Key.new(decrypt(key)) if key
    end
  end

  def dump_keys
    JSON.dump(keys.each_with_object({}) {|(k,v),m| m[k]= encrypt(v.key.to_pem)})
  end

  def new_cipher
    # Re-using the cipher between keys has weird behaviours with openssl3
    # Using a fresh key instead of memoizing it on the client simplifies things
    OpenSSL::Cipher.new('aes-256-cbc')
  end

  def encrypt(data)
    salt = OpenSSL::Random.random_bytes(8)

    cipher = setup_cipher(:encrypt, self.passphrase, salt)
    Base64.strict_encode64([salt, cipher.update(data) + cipher.final].join)
  end

  def decrypt(data)
    data = Base64.strict_decode64(data)
    salt = data[0..7]
    data = data[8..-1]

    cipher = setup_cipher(:decrypt, self.passphrase, salt)
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

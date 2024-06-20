class Epics::Client
  extend Forwardable

  attr_accessor :passphrase, :url, :host_id, :user_id, :partner_id, :keys, :keys_content
  attr_writer :iban, :bic, :name

  def_delegators :connection, :post

  def initialize(keys_content, passphrase, url, host_id, user_id, partner_id)
    self.keys_content = keys_content.respond_to?(:read) ? keys_content.read : keys_content if keys_content
    self.passphrase = passphrase
    self.keys = extract_keys if keys_content
    self.url  = url
    self.host_id    = host_id
    self.user_id    = user_id
    self.partner_id = partner_id
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

  def self.setup(passphrase, url, host_id, user_id, partner_id, keysize = 2048)
    client = new(nil, passphrase, url, host_id, user_id, partner_id)
    client.keys = %w(A006 X002 E002).each_with_object({}) do |type, memo|
      memo[type] = Epics::Key.new( OpenSSL::PKey::RSA.generate(keysize) )
    end

    client
  end

  def ini_letter(bankname)
    raw = File.read(File.join(File.dirname(__FILE__), '../letter/', 'ini.erb'))
    ERB.new(raw).result(binding)
  end

  def save_ini_letter(bankname, path)
    File.write(path, ini_letter(bankname))
    path
  end

  def credit(document)
    self.CCT(document)
  end

  def debit(document, type = :CDD)
    self.public_send(type, document)
  end

  def statements(from, to, type = :STA)
    self.public_send(type, from, to)
  end

  def HIA
    post(url, Epics::HIA.new(self).to_xml).body.ok?
  end

  def INI
    post(url, Epics::INI.new(self).to_xml).body.ok?
  end

  def HPB
    Nokogiri::XML(download(Epics::HPB)).xpath("//xmlns:PubKeyValue", xmlns: "urn:org:ebics:H004").each do |node|
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
    upload(Epics::CDB, document)
  end

  def C2S(document)
    upload(Epics::C2S, document)
  end

  def CDD(document)
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
    upload(Epics::CCT, document)
  end

  def CCS(document)
    upload(Epics::CCS, document)
  end

  def XCT(document)
    upload(Epics::XCT, document)
  end

  def STA(from = nil, to = nil)
    download(Epics::STA, from, to)
  end

  def VMK(from = nil, to = nil)
    download(Epics::VMK, from, to)
  end

  def CDZ(from = nil, to = nil)
    download_and_unzip(Epics::CDZ, from, to)
  end

  def CRZ(from = nil, to = nil)
    download_and_unzip(Epics::CRZ, from, to)
  end

  def C52(from, to)
    download_and_unzip(Epics::C52, from, to)
  end

  def C53(from, to)
    download_and_unzip(Epics::C53, from, to)
  end

  def C54(from, to)
    download_and_unzip(Epics::C54, from, to)
  end

  def Z52(from, to)
    download_and_unzip(Epics::Z52, from, to)
  end

  def Z53(from, to)
    download_and_unzip(Epics::Z53, from, to)
  end

  def Z54(from, to)
    download_and_unzip(Epics::Z54, from, to)
  end

  def HAA
    Nokogiri::XML(download(Epics::HAA)).at_xpath("//xmlns:OrderTypes", xmlns: "urn:org:ebics:H004").content.split(/\s/)
  end

  def HTD
    Nokogiri::XML(download(Epics::HTD)).tap do |htd|
      @iban        ||= htd.at_xpath("//xmlns:AccountNumber[@international='true']", xmlns: "urn:org:ebics:H004").text rescue nil
      @bic         ||= htd.at_xpath("//xmlns:BankCode[@international='true']", xmlns: "urn:org:ebics:H004").text rescue nil
      @name        ||= htd.at_xpath("//xmlns:Name", xmlns: "urn:org:ebics:H004").text rescue nil
      @order_types ||= htd.search("//xmlns:OrderTypes", xmlns: "urn:org:ebics:H004").map{|o| o.content.split(/\s/) }.delete_if{|o| o == ""}.flatten
    end.to_xml
  end

  def HPD
    download(Epics::HPD)
  end

  def HKD
    download(Epics::HKD)
  end

  def PTK(from, to)
    download(Epics::PTK, from, to)
  end

  def HAC(from = nil, to = nil)
    download(Epics::HAC, from, to)
  end

  def save_keys(path)
    File.write(path, dump_keys)
  end

  private

  def upload(order_type, document)
    order = order_type.new(self, document)
    res = post(url, order.to_xml).body
    order.transaction_id = res.transaction_id

    order_id = res.order_id

    res = post(url, order.to_transfer_xml).body

    return res.transaction_id, [res.order_id, order_id].detect { |id| id.to_s.chars.any? }
  end

  def download(order_type, *args)
    document = order_type.new(self, *args)
    res = post(url, document.to_xml).body
    document.transaction_id = res.transaction_id

    if res.segmented? && res.last_segment?
      post(url, document.to_receipt_xml).body
    end

    res.order_data
  end

  def download_and_unzip(order_type, *args)
    [].tap do |entries|
      Zip::File.open_buffer(StringIO.new(download(order_type, *args))).each do |zipfile|
        entries << zipfile.get_input_stream.read
      end
    end
  end

  def connection
    @connection ||= Faraday.new(headers: { 'Content-Type' => 'text/xml', user_agent: "EPICS v#{Epics::VERSION}"}, ssl: { verify: verify_ssl? }) do |faraday|
      faraday.use Epics::XMLSIG, { client: self }
      faraday.use Epics::ParseEbics, { client: self}
      # faraday.use MyAdapter
      # faraday.response :logger                  # log requests to STDOUT
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

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

  def h3k_unsigned_order_data(subscriber) 
    h3k = Epics::H3K.new(self)
    h3k.unsigned_order_data(subscriber.es_cert, subscriber.auth_cert, subscriber.encrypt_cert)
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

  def H3K(signature, order_data)
    request = Epics::H3K.new(self).to_xml(signature, order_data)
    File.open(File.dirname(__FILE__) + '/../../h3k.xml', 'wb') { |f| f.print request }
    post(url, request).body.ok?
  end

  def HPB
    Nokogiri::XML(download(Epics::HPB)).xpath("//xmlns:PubKeyValue", xmlns: "urn:org:ebics:H004").each do |node|
      type = node.parent.last_element_child.content

      modulus  = Base64.decode64(node.at_xpath(".//*[local-name() = 'Modulus']").content)
      exponent = Base64.decode64(node.at_xpath(".//*[local-name() = 'Exponent']").content)

      bank   = OpenSSL::PKey::RSA.new
      bank.n = OpenSSL::BN.new(modulus, 2)
      bank.e = OpenSSL::BN.new(exponent, 2)

      self.keys["#{host_id.upcase}.#{type}"] = Epics::Key.new(bank)
    end

    [bank_x, bank_e]
  end

  def CD1(document)
    upload(Epics::CD1, document)
  end

  def CDD(document)
    upload(Epics::CDD, document)
  end

  def CCT(document)
    upload(Epics::CCT, document)
  end

  def STA(from = nil, to = nil)
    download(Epics::STA, from, to)
  end

  def C52(from, to)
    download_and_unzip(Epics::C52, from, to)
  end

  def C53(from, to)
    download_and_unzip(Epics::C53, from, to)
  end

  def HAA
    Nokogiri::XML(download(Epics::HAA)).at_xpath("//xmlns:OrderTypes", xmlns: "urn:org:ebics:H004").content.split(/\s/)
  end

  def HTD
    Nokogiri::XML(download(Epics::HTD)).tap do |htd|
      @iban ||= htd.at_xpath("//xmlns:AccountNumber[@international='true']", xmlns: "urn:org:ebics:H004").text
      @bic  ||= htd.at_xpath("//xmlns:BankCode[@international='true']", xmlns: "urn:org:ebics:H004").text
      @name ||= htd.at_xpath("//xmlns:Name", xmlns: "urn:org:ebics:H004").text
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

    res = post(url, order.to_transfer_xml).body

    return res.transaction_id, res.order_id
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
      Zip::InputStream.open(StringIO.new( download(order_type, *args) )) do |stream|
        while stream.get_next_entry
          entries << stream.read
        end
      end
    end
  end

  def connection
    @connection ||= Faraday.new(headers: {user_agent: "EPICS v#{Epics::VERSION}"}) do |faraday|
      faraday.use Epics::XMLSIG, { client: self }
      faraday.use Epics::ParseEbics, { client: self}
      # faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
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

  def cipher
    @cipher ||= OpenSSL::Cipher::Cipher.new("aes-256-cbc")
  end

  def encrypt(data)
    salt = OpenSSL::Random.random_bytes(8)

    setup_cipher(:encrypt, self.passphrase, salt)
    Base64.strict_encode64([salt, cipher.update(data) + cipher.final].join)
  end

  def decrypt(data)
    data = Base64.strict_decode64(data)
    salt = data[0..7]
    data = data[8..-1]

    setup_cipher(:decrypt, self.passphrase, salt)
    cipher.update(data) + cipher.final
  end

  def setup_cipher(method, passphrase, salt)
    cipher.send(method)
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(passphrase, salt, 1, cipher.key_len)
  end

end

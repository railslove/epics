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
    client = Client.new(nil, passphrase, url, host_id, user_id, partner_id)
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
    @client.CCT(document)
  end

  def debit(document, type = :CDD)
    @client.send(type, document)
  end

  def statements(from, to, type = :STA)
    @client.send(type, from, to)
  end

  def HIA
    order = Epics::HIA.new(self)

    puts order.to_xml

    res = post(url, order.to_xml).body

    res.ok?
  end

  def INI
    order = Epics::INI.new(self)

    puts order.to_xml

    res = post(url, order.to_xml).body

    res.ok?
  end

  def HPB
    Nokogiri::XML(download(Epics::HPB)).xpath("//xmlns:PubKeyValue").each do |node|
      type = node.parent.last_element_child.content

      modulus  = Base64.decode64(node.at_xpath(".//ds:Modulus").content)
      exponent = Base64.decode64(node.at_xpath(".//ds:Exponent").content)

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

  def STA(from, to)
    download(Epics::STA, from, to)
  end

  def HAA
    Nokogiri::XML(download(Epics::HAA)).at_xpath("//xmlns:OrderTypes").content.split(/\s/)
  end

  def HTD
    Nokogiri::XML(download(Epics::HTD)).tap do |htd|
      @iban ||= htd.at_xpath("//xmlns:AccountNumber[@international='true']").text
      @bic  ||= htd.at_xpath("//xmlns:BankCode[@international='true']").text
      @name ||= htd.at_xpath("//xmlns:Name").text
    end.to_xml
  end

  def HPD
    download(Epics::HPD)
  end

  def PTK(from, to)
    download(Epics::PTK, from, to)
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

    res.transaction_id
  end

  def download(order_type, *args)
    document = order_type.new(self, *args)
    res = post(url, document.to_xml).body

    res.order_data
  end

  def connection
    @connection ||= Faraday.new do |faraday|
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

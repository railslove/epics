class Epics::Client
  extend Forwardable

  attr_accessor :passphrase, :url, :host_id, :user_id, :partner_id, :keys, :keys_file

  def_delegators :connection, :post

  def initialize(keys_file, passphrase, url, host_id, user_id, partner_id)
    self.keys_file = keys_file
    self.passphrase = passphrase
    self.keys = extract_keys
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

  def HIA
    document = Epics::HIA.new(self)

    post(self.url, document.to_xml).body
  end

  def INI
    document = Epics::INI.new(self)

    post(self.url, document.to_xml).body
  end

  def ini_letter(bankname, path)
    raw = File.read(File.join(File.dirname(__FILE__), '../letter/', 'ini.erb'))
    File.write(path, ERB.new(raw).result(binding))

    path
  end

  def HPB
    res = post(url, Epics::HPB.new(self).to_xml).body
    hpb = Nokogiri::XML.parse(res.order_data)

    hpb.xpath("//xmlns:PubKeyValue").each do |node|
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
    cd1 = Epics::CD1.new(self, document)

    res = post(url, cd1.to_xml).body

    cd1.transaction_id = res.transaction_id

    res = post(url, cd1.to_transfer_xml).body

    res.transaction_id
  end

  def STA(from, to)
    document = Epics::STA.new(self, from, to)

    res = post(url, document.to_xml).body

    res.order_data
  end

  def HAA
    document = Epics::HAA.new(self)
    res = post(url, document.to_xml).body

    Nokogiri::XML(res.order_data).xpath("//xmlns:OrderTypes").first.content.split(/\s/)
  end

  def HTD
    document = Epics::HTD.new(self)
    res = post(url, document.to_xml).body

    res.order_data
  end

  def HPD
    document = Epics::HPD.new(self)
    res = post(url, document.to_xml).body

    res.order_data
  end

  def PTK(from, to)
    document = Epics::PTK.new(self, from, to)
    res = post(url, document.to_xml).body

    res.order_data
  end

  private

  def connection
    @connection ||= Faraday.new do |faraday|
      faraday.use Epics::XMLSIG, { client: self }
      faraday.use Epics::ParseEbics, {content_type: /.+/, client: self}
      # faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  def extract_keys
    MultiJson.load(File.read(keys_file)).each_with_object({}) do |(type, key), memo|
      memo[type] = Epics::Key.new(decrypt(key)) if key
    end
  end

  def write_keys
    File.write(keys_file, MultiJson.dump(keys.each_with_object({}) {|(k,v),m| m[k]= encrypt(v.key.to_pem)}, pretty: true))
  end

  def cipher
    @cipher ||= OpenSSL::Cipher::Cipher.new("aes-256-cbc")
  end

  def encrypt(data)
    salt = OpenSSL::Random.random_bytes(8)

    setup_cipher(:encrypt, self.passphrase, salt)
    cipher.update(data) + cipher.final
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

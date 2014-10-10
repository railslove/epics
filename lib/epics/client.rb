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

  def HPB
    res = post(url, Epics::HPB.new(self).to_xml).body
    hpb = Nokogiri::XML.parse(res.order_data)

    [
      self.keys["#{host_id.upcase}.X002"] = new_auth_key_x002(hpb),
      self.keys["#{host_id.upcase}.E002"] = new_encryption_key_e002(hpb)
    ]
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

  def new_auth_key_x002(hpb)
    auth_key_modulus  = Base64.decode64(hpb.xpath("//xmlns:PubKeyValue/ds:RSAKeyValue/ds:Modulus").first.content)
    auth_key_exponent = Base64.decode64(hpb.xpath("//xmlns:PubKeyValue/ds:RSAKeyValue/ds:Exponent").first.content)

    generate_key(auth_key_modulus, auth_key_exponent)
  end

  def new_encryption_key_e002(hpb)
    encryption_key_modulus  = Base64.decode64(hpb.xpath("//xmlns:PubKeyValue/ds:RSAKeyValue/ds:Modulus").last.content)
    encryption_key_exponent = Base64.decode64(hpb.xpath("//xmlns:PubKeyValue/ds:RSAKeyValue/ds:Exponent").last.content)

    generate_key(encryption_key_modulus, encryption_key_exponent)
  end

  def generate_key(modulus, exponent)
    bank_k   = OpenSSL::PKey::RSA.new
    bank_k.n = OpenSSL::BN.new(modulus, 2)
    bank_k.e = OpenSSL::BN.new(exponent, 2)
    Epics::Key.new(bank_k)
  end

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
      memo[type] = Epics::Key.new(Base64.decode64(key)) if key
    end
  end

  def write_keys
    File.write(keys_file, MultiJson.dump(keys.each_with_object({}) {|(k,v),m| m[k]= Base64.encode64(v.key.to_der)}, pretty: true))
  end

end

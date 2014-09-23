class Epics::Client
  extend Forwardable

  attr_accessor :passphrase, :url, :host_id, :user_id, :partner_id, :keys, :keys_file

  def_delegators :connection, :post

  def initialize(keys_file, passphrase, url, host_id, user_id, partner_id)
    self.keys_file = keys_file
    self.keys = extract_keys
    self.url  = url
    self.host_id    = host_id
    self.user_id    = user_id
    self.partner_id = partner_id
  end

  def e
    self.keys["E002"]
  end

  def a
    self.keys["A006"]
  end

  def x
    self.keys["X002"]
  end

  def bank_e
    self.keys["#{host_id.upcase}.E002"]
  end

  def bank_x
    self.keys["#{host_id.upcase}.X002"]
  end

  def HPB
    document = Epics::HPB.new(self)

    res = post(self.url, document.to_xml).body

    hpb = Nokogiri::XML.parse(res.order_data)

    auth_key_modulus  = Base64.decode64(hpb.xpath("//xmlns:PubKeyValue/ds:RSAKeyValue/ds:Modulus").first.content).to_hex_string(false)
    auth_key_exponent = Base64.decode64(hpb.xpath("//xmlns:PubKeyValue/ds:RSAKeyValue/ds:Exponent").first.content).to_hex_string(false)

    bank_k   = OpenSSL::PKey::RSA.new
    bank_k.n = OpenSSL::BN.new(auth_key_modulus, 16)
    bank_k.e = OpenSSL::BN.new(auth_key_exponent, 16)

    self.keys["#{host_id.upcase}.X002"] = Epics::Key.new(bank_k)

    encyption_key_modulus  = Base64.decode64(hpb.xpath("//xmlns:PubKeyValue/ds:RSAKeyValue/ds:Modulus").last.content).to_hex_string(false)
    encyption_key_exponent = Base64.decode64(hpb.xpath("//xmlns:PubKeyValue/ds:RSAKeyValue/ds:Exponent").last.content).to_hex_string(false)

    bank_k = OpenSSL::PKey::RSA.new
    bank_k.n = OpenSSL::BN.new(encyption_key_modulus, 16)
    bank_k.e = OpenSSL::BN.new(encyption_key_exponent, 16)

    self.keys["#{host_id.upcase}.E002"] = Epics::Key.new(bank_k)
  end

  def CD1(document)
    cd1 = Epics::CD1.new(self, document)

    res = post(self.url, cd1.to_xml).body

    cd1.transaction_id = res.transaction_id

    res = post(self.url, cd1.to_transfer_xml).body

    res.transaction_id
  end

  def STA(from, to)
    document = Epics::STA.new(self, from, to)

    res = post(self.url, document.to_xml).body

    res.order_data
  end

  def HAA
    document = Epics::HAA.new(self)
    res = post(self.url, document.to_xml).body

    res.order_data
  end

  def HTD
    document = Epics::HTD.new(self)
    res = post(self.url, document.to_xml).body

    res.order_data
  end

  def HPD
    document = Epics::HPD.new(self)
    res = post(self.url, document.to_xml).body

    res.order_data
  end

  def PTK(from, to)
    document = Epics::PTK.new(self, from, to)
    res = post(self.url, document.to_xml).body

    res.order_data
  end

  private

  def connection
    @connection ||= Faraday.new do |faraday|
      faraday.use Epics::XMLSIG, { client: self }
      faraday.use Epics::ParseEbics, {content_type: "text/plain", client: self}
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  def extract_keys
    MultiJson.load(File.read(self.keys_file)).each_with_object({}) do |(type, key), memo|
      memo[type] = Epics::Key.new(Base64.decode64(key)) if key
    end
  end

  def write_keys
    File.write(self.keys_file, MultiJson.dump(keys.each_with_object({}) {|(k,v),m| m[k]= Base64.encode64(v.key.to_der)}, pretty: true))
  end

end

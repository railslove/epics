class Epics::Signer
  attr_accessor :doc, :client

  def initialize(client, doc = nil)
    self.doc = Nokogiri::XML.parse(doc) if doc
    self.client = client
  end

  def digest!
    content_to_digest = Base64.encode64(digester.digest(doc.xpath("//*[@authenticate='true']").map(&:canonicalize).join)).strip

    if digest_node
      digest_node.content = content_to_digest
    end

    doc
  end

  def sign!
    signature_value_node = doc.xpath("//ds:SignatureValue").first

    if signature_node
      signature_value_node.content = Base64.encode64(client.authentication_key.key.sign(digester, signature_node.canonicalize)).gsub(/\n/,'')
    end

    doc
  end

  def digest_node
    @d ||= doc.xpath("//ds:DigestValue").first
  end

  def signature_node
    @s ||= doc.xpath("//ds:SignedInfo").first
  end

  def digester
    OpenSSL::Digest::SHA256.new
  end
end

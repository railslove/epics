class Epics::Signer
  attr_accessor :doc, :user_key

  def initialize(doc, user_key)
    self.doc = Nokogiri::XML.parse(doc)
    self.user_key = user_key
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
      signature_value_node.content = Base64.encode64(user_key.key.sign(digester, signature_node.canonicalize)).gsub(/\n/,'')
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
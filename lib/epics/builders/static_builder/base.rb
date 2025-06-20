class Epics::Builders::StaticBuilder::Base
  def initialize
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      xml.static do
        yield self
      end
    end
  end

  def add_host_id(host_id)
    @xml.HostID host_id
    self
  end

  def add_nonce(data)
    @xml.Nonce data
    self
  end

  def add_random_nonce
    add_nonce SecureRandom.hex(16)
  end

  def add_timestamp(datetime)
    @xml.Timestamp datetime.iso8601
    self
  end

  def add_partner_id(partner_id)
    @xml.PartnerID partner_id
    self
  end

  def add_user_id(user_id)
    @xml.UserID user_id
    self
  end

  def add_product(product, language)
    @xml.Product product, Language: language
    self
  end

  def add_order_details
    raise NotImplementedError
  end

  def add_num_segments(num_segments)
    @xml.NumSegments num_segments
    self
  end

  def add_bank_pubbey_digests(authentication_version, authentication_digest, encryption_version, encryption_digest, algorithm = 'sha256')
    @xml.BankPubKeyDigests do
      @xml.Authentication Base64.strict_encode64(authentication_digest), Version: authentication_version, Algorithm: "http://www.w3.org/2001/04/xmlenc##{algorithm}"
      @xml.Encryption Base64.strict_encode64(encryption_digest), Version: encryption_version, Algorithm: "http://www.w3.org/2001/04/xmlenc##{algorithm}"
    end
    self
  end

  def add_security_medium(security_medium)
    @xml.SecurityMedium security_medium
    self
  end

  def add_transaction_id(transaction_id)
    @xml.TransactionID transaction_id
    self
  end

  def doc
    @xml.doc.root
  end
end

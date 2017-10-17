class Epics::HPB < Epics::GenericRequest
  def root
    "ebicsNoPubKeyDigestsRequest"
  end

  def header
     Nokogiri::XML::Builder.new do |xml|
      xml.header(authenticate: true) {
        xml.static {
          xml.HostID host_id
          xml.Nonce nonce
          xml.Timestamp timestamp
          xml.PartnerID partner_id
          xml.UserID user_id
          xml.Product("EPICS - a ruby ebics kernel", 'Language' => 'de')
          xml.OrderDetails {
            xml.OrderType 'HPB'
            xml.OrderAttribute 'DZHNN'
          }
          xml.SecurityMedium '0000'
        }
        xml.mutable ''
      }
    end.doc.root
  end
end

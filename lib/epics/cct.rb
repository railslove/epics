class Epics::CCT < Epics::GenericUploadRequest
  def order_attribute
    'OZHNN'
  end

  def order_type
    'CCT'
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
            xml.OrderType order_type
            xml.OrderAttribute order_attribute
            xml.StandardOrderParams
          }
          xml.BankPubKeyDigests {
            xml.Authentication(client.bank_x.public_digest, Version: 'X002', Algorithm: "http://www.w3.org/2001/04/xmlenc#sha256")
            xml.Encryption(client.bank_e.public_digest, Version: 'E002', Algorithm: "http://www.w3.org/2001/04/xmlenc#sha256" )
          }
          xml.SecurityMedium '0000'
          xml.NumSegments 1
        }
        xml.mutable {
          xml.TransactionPhase 'Initialisation'
        }
      }
    end.doc.root
  end
end

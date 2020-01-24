class Epics::FDL < Epics::GenericRequest
  attr_accessor :file_format

  def initialize(client, file_format)
    super(client)
    self.file_format = file_format
  end


  def header
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.header(authenticate: true) {
        xml.static {
          xml.HostID host_id
          xml.Nonce nonce
          xml.Timestamp timestamp
          xml.PartnerID partner_id
          xml.UserID user_id
          xml.Product("EPICS - a ruby ebics kernel", 'Language' => 'de')
          xml.OrderDetails {
            xml.OrderType 'FDL'
            xml.OrderID "A00A"
            xml.OrderAttribute "DZHNN"
            xml.FDLOrderParams {
              xml.FileFormat file_format
            }
          }
          xml.BankPubKeyDigests {
            xml.Authentication(client.bank_x.public_digest, Version: 'X002', Algorithm: "http://www.w3.org/2001/04/xmlenc#sha256")
            xml.Encryption(client.bank_e.public_digest, Version: 'E002', Algorithm: "http://www.w3.org/2001/04/xmlenc#sha256" )
          }
          xml.SecurityMedium "0000"
        }
        xml.mutable {
          xml.TransactionPhase 'Initialisation'
        }
      }
    end
    xml_string = builder.to_xml 
    File.open('/tmp/file.xml', 'w') do |file|
      # write the xml string generated above to the file
      file.write xml_string
    end
    builder.doc.root
  end
end

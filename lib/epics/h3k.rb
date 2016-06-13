require 'date'
require 'zlib'
require 'nokogiri'
require 'base64'
require 'openssl'
require_relative 'mgf'
require_relative 'signer_cert'

class Epics::H3K < Epics::GenericRequest

  def ebics_unsigned_request(host_id, partner_id, user_id, system_id='')

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.ebicsUnsignedRequest(
        xmlns: "urn:org:ebics:H004", 
        "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#", 
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "urn:org:ebics:H004 ebics_keymgmt_request_H004.xsd",
        Version: "H004",
        Revision: "1" ) {
        xml.header(authenticate: "true") {
          xml.static {
            xml.HostID host_id         
            xml.PartnerID partner_id
            xml.UserID user_id
            xml.SystemID system_id
            xml.Product(Language: "de") { xml.text "EPICS - a ruby ebics kernel" }
            xml.OrderDetails { 
              xml.OrderType "H3K"
              xml.OrderAttribute "OZNNN"
            }
            xml.SecurityMedium "0000"
          }
          xml.mutable {}
        }
        xml.body {
          xml.DataTransfer {
            xml.SignatureData(authenticate: true){ xml.text signature_data }
            xml.OrderData order_data
          }
        }
      }
    end
    builder.to_xml
  end



  def h3k_request_order_data

    #TODO: xml needs correct values
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.H3KRequestOrderData(
        xmlns: "urn:org:ebics:H004", 
        "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#", 
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "urn:org:ebics:H004 ebics_orders_H004.xsd") {
        xml.SignatureCertificateInfo {
          xml['ds'].X509Data {
            xml.X509SubjectName "bla"
          }
          xml.SignatureVersion "A006"
        }
        xml.AuthenticationCertificateInfo {
          xml['ds'].X509Data {
            xml.X509SubjectName "bla"
          }
          xml.AuthenticationVersion "X002"
        }
        xml.EncryptionCertificateInfo {
          xml['ds'].X509Data {
            xml.X509SubjectName "bla"
          }
          xml.EncryptionVersion "E002"
        }
        xml.PartnerID "999888777"
        xml.UserID "USERID"
      }
    end
    builder.to_xml
  end


  def order_data
    data = h3k_request_order_data
    data_bin = compress(data)
    data_base_64 = encode(data_bin)
  end


  def signature_data
    key = OpenSSL::PKey::RSA.new(2048) #Should be provided, will generate here for testing
    signature = Epics::Signer_cert.new(key, h3k_request_order_data)
    signature_bin = compress(data)
    signature_base_64 = encode(data_bin)
  end



  ###   Helper Methods from the block above    ###

  def compress(data)
    Zlib::Deflate.deflate(data)
  end

  def encode(data)
    Base64.encode64(data)
  end

end

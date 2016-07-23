require 'date'
require 'zlib'
require 'nokogiri'
require 'base64'
require 'openssl'
require_relative 'mgf'

class Epics::H3K < Epics::GenericRequest

  def to_xml(signature, order_data)
    ebics_unsigned_request(signature, order_data)
  end

  def ebics_unsigned_request(signature, order_data)

    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.ebicsUnsignedRequest(
        xmlns: 'urn:org:ebics:H004',
        'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'urn:org:ebics:H004 ebics_keymgmt_request_H004.xsd',
        Version: 'H004',
        Revision: '1' ) {
        xml.header(authenticate: 'true') {
          xml.static {
            xml.HostID host_id
            xml.PartnerID partner_id
            xml.UserID user_id
            xml.Product(Language: 'de') { xml.text 'EPICS - a ruby ebics kernel' }
            xml.OrderDetails { 
              xml.OrderType 'H3K'
              xml.OrderAttribute 'OZNNN'
            }
            xml.SecurityMedium '0000'
          }
          xml.mutable {}
        }
        xml.body {
          xml.DataTransfer {
            xml.SignatureData(authenticate: true){ xml.text Base64.encode64( Zlib::Deflate.deflate(Base64.urlsafe_decode64(signature))) }
            xml.OrderData Base64.encode64(Zlib::Deflate.deflate(order_data))
          }
        }
      }
    end
    builder.to_xml
  end

  def unsigned_order_data(es_certificate, auth_certificate, encrypt_certificate)
    
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.H3KRequestOrderData(
        xmlns: 'urn:org:ebics:H004',
        'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'urn:org:ebics:H004 ebics_orders_H004.xsd') {
        xml.SignatureCertificateInfo {
          xml['ds'].X509Data {
            xml.X509Certificate es_certificate
          }
          xml.SignatureVersion 'A006'
        }
        xml.AuthenticationCertificateInfo {
          xml['ds'].X509Data {
            xml.X509Certificate auth_certificate
          }
          xml.AuthenticationVersion 'X002'
        }
        xml.EncryptionCertificateInfo {
          xml['ds'].X509Data {
            xml.X509Certificate encrypt_certificate
          }
          xml.EncryptionVersion 'E002'
        }
        xml.PartnerID partner_id
        xml.UserID user_id
      }
    end
    builder.to_xml
  end

end

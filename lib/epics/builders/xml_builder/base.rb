class Epics::Builders::XmlBuilder::Base
  EBICS_REQUEST = 'ebicsRequest'
  EBICS_UNSECURED_REQUEST = 'ebicsUnsecuredRequest'
  EBICS_UNSIGNED_REQUEST = 'ebicsUnsignedRequest'
  EBICS_NO_PUB_KEY_DIGESTS = 'ebicsNoPubKeyDigestsRequest'
  EBICS_HEV = 'ebicsHEVRequest'

  def initialize
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
    end
  end

  def create_unsecured(&)
    create_h00x(EBICS_UNSECURED_REQUEST, &)
  end

  def create_secured_no_pubkey_digests(&)
    create_h00x(EBICS_NO_PUB_KEY_DIGESTS, true, &)
  end

  def create_secured(&)
    create_h00x(EBICS_REQUEST, true, &)
  end

  def create_unsigned(&)
    create_h00x(EBICS_UNSIGNED_REQUEST, &)
  end

  def create_hev(&)
    create_h000(EBICS_HEV, &)
  end

  def add_header
    raise NotImplementedError
  end

  def add_body
    raise NotImplementedError
  end

  def add_host_id(host_id)
    @xml.HostID host_id
    self
  end

  def xml
    @xml
  end

  def to_xml
    @xml.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end

  protected

  def h00x_version
    raise NotImplementedError
  end

  def h00x_namespace
    raise NotImplementedError
  end

  private

  def create_h00x(container, secured = false)
    namespaces = { xmlns: h00x_namespace }
    namespaces['xmlns:ds'] = 'http://www.w3.org/2000/09/xmldsig#' if secured
    attributes = { Version: h00x_version, Revision: '1' }
    @xml.send(container, **namespaces, **attributes) do
      yield self
    end
    self
  end

  def create_h000(container)
    namespaces = { xmlns: 'http://www.ebics.org/H000' }
    namespaces['xmlns:xsi'] = 'http://www.w3.org/2001/XMLSchema-instance'
    namespaces['xsi:schemaLocation'] = 'http://www.ebics.org/H000 http://www.ebics.org/H000/ebics_hev.xsd'
    @xml.send(container, **namespaces) do
      yield self
    end
    self
  end
end
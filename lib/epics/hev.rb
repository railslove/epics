class Epics::HEV < Epics::GenericRequest
  def root
    "ebicsHEVRequest"
  end

  def body
    Nokogiri::XML::Builder.new do |xml|
      xml.HostID host_id
    end.doc.root
  end

  def to_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.send(root, 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:schemaLocation' => 'http://www.ebics.org/H000 http://www.ebics.org/H000/ebics_hev.xsd', 'xmlns' => 'http://www.ebics.org/H000') {
        xml.parent.add_child(body)
      }
    end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end
end

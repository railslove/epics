require 'nokogiri'

require_relative './h004/hvu'
require_relative './h004/hvz'
require_relative './h004/hvd'

module Epics
  module H004
    UnknownInput = Class.new(ArgumentError)

    def self.from_xml(raw_xml)
      doc = Nokogiri::XML(raw_xml).at_xpath('/*')

      unless doc.namespace.href == "urn:org:ebics:H004"
        fail UnknownInput, "Unknown xml file contents"
      end

      case doc.name
      when "HVZResponseOrderData"
        Epics::H004::HVZ.new(doc)
      when "HVUResponseOrderData"
        Epics::H004::HVU.new(doc)
      when "HVDResponseOrderData"
        Epics::H004::HVD.new(doc)
      end
    rescue Nokogiri::XML::XPath::SyntaxError => ex
      fail UnknownInput, "Invalid XML input data: #{ex.message}"
    end
  end
end

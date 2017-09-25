module Epics
  module H004
    class HVD
      attr_accessor :doc

      def initialize(xml_doc)
        self.doc = xml_doc
      end

      def to_h
        order = doc.at_xpath("/h004:HVDResponseOrderData")
        {
          signers: signers(order.xpath('./h004:SignerInfo')),
          order_details_available: order.at_xpath('./h004:OrderDetailsAvailable').content == 'true',
          order_data_available: order.at_xpath('./h004:OrderDataAvailable').content == 'true',
          digest: order.at_xpath('./h004:DataDigest').content,
          digest_signature_version: order.at_xpath('./h004:DataDigest')['SignatureVersion'],
          display_file: Base64.decode64(order.at_xpath('./h004:DisplayFile').content).encode("UTF-8", "ISO-8859-15"),
        }
      end

      private

      def originator(node)
        {
          name: node.at_xpath('./h004:Name').content.strip,
          partner_id: node.at_xpath('./h004:PartnerID').content.strip,
          user_id: node.at_xpath('./h004:UserID').content.strip,
          timestamp: Time.parse(node.at_xpath('./h004:Timestamp').content),
        }
      end

      def signers(nodes)
        nodes.map do |signer|
          {
            name: signer.at_xpath('./h004:Name').content.strip,
            partner_id: signer.at_xpath('./h004:PartnerID').content.strip,
            user_id: signer.at_xpath('./h004:UserID').content.strip,
            signature_class: signer.at_xpath('./h004:Permission')['AuthorisationLevel']
          }
        end
      end

    end
  end
end

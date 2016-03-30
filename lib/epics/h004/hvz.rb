require 'bigdecimal'

module Epics
  module H004
    class HVZ
      attr_accessor :doc

      def initialize(xml_doc)
        self.doc = xml_doc
      end

      def to_h
        doc.xpath("/h004:HVZResponseOrderData/h004:OrderDetails").map do |order|
          {
            order_id: order.at_xpath('./h004:OrderID').content,
            order_type: order.at_xpath('./h004:OrderType').content,
            originator: originator(order.at_xpath('./h004:OriginatorInfo')),
            signers: signers(order.xpath('./h004:SignerInfo')),
            required_signatures: order.at_xpath('./h004:SigningInfo')['NumSigRequired'].to_i,
            applied_signatures: order.at_xpath('./h004:SigningInfo')['NumSigDone'].to_i,
            ready_for_signature: as_boolean(order.at_xpath('./h004:SigningInfo')['readyToBeSigned']),
            total_amount: BigDecimal.new(order.at_xpath('./h004:TotalAmount').content),
            total_amount_type: as_boolean(order.at_xpath('./h004:TotalAmount')['isCredit']) ? 'credit' : 'debit',
            total_orders: order.at_xpath('./h004:TotalOrders').content.to_i,
            digest: order.at_xpath('./h004:DataDigest').content,
            digest_signature_version: order.at_xpath('./h004:DataDigest')['SignatureVersion'],
          }
        end
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

      def as_boolean(input)
        input.to_s.downcase == 'true'
      end
    end
  end
end

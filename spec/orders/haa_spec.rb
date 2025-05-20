RSpec.describe Epics::HAA do
  let(:client) { Epics::Client.new( File.open(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS', version:) }

  subject { described_class.new(client) }

  before { allow(SecureRandom).to receive(:hex).with(16).and_return('95149241ead8ae7dbb72cabe966bf0e3') }
  before { allow(Time).to receive(:now).and_return(Time.parse('2017-10-17T19:56:33Z')) }

  describe 'order attributes' do
    let(:version) { Epics::Keyring::VERSION_25 }

    it { expect(subject.to_xml).to include('<OrderAttribute>DZHNN</OrderAttribute>') }
    it { expect(subject.to_xml).to include('<OrderType>HAA</OrderType>') }
  end

  include_examples '#to_xml'
  include_examples '#to_receipt_xml'

  describe '#to_xml' do
    let(:version) { Epics::Keyring::VERSION_25 }

    describe 'validate against fixture' do
      let(:signature_order_data) {
        doc = Nokogiri::XML(File.read(File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'haa.xml')))
        doc.xpath('//text()').each { |node| node.content = '' if node.text =~ /\A\s+\z/m }
        doc
      }

      it 'will match exactly' do
        expect(Nokogiri::XML(subject.to_xml)).to be_equivalent_to(signature_order_data)
      end
    end
  end

  describe '#to_receipt_xml' do
    let(:version) { Epics::Keyring::VERSION_25 }

    describe 'validate against fixture' do
      let(:signature_order_data) { Nokogiri::XML(File.read(File.join( File.dirname(__FILE__), '..', 'fixtures', 'xml', 'haa_receipt.xml'))) }

      it 'will match exactly' do
        expect(Nokogiri::XML(subject.to_receipt_xml)).to be_equivalent_to(signature_order_data)
      end
    end
  end
end

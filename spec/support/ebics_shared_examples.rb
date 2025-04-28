RSpec.shared_examples '#to_xml' do |versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25]|
  describe '#to_xml' do
    versions.each do |version|
      context version do
        let(:version) { version }
        specify { expect(subject.to_xml).to be_a_valid_ebics_doc(version) }
      end
    end
  end
end

RSpec.shared_examples '#to_transfer_xml' do |versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25]|
  describe '#to_transfer_xml' do
    versions.each do |version|
      context version do
        let(:version) { version }
        before { subject.transaction_id = SecureRandom.hex(16) }
        specify { expect(subject.to_transfer_xml).to be_a_valid_ebics_doc(version) }
      end
    end
  end
end

RSpec.shared_examples '#to_receipt_xml' do |versions: [Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25]|
  describe '#to_receipt_xml' do
    versions.each do |version|
      context version do
        let(:version) { version }
        before { subject.transaction_id = SecureRandom.hex(16) }
        specify { expect(subject.to_receipt_xml).to be_a_valid_ebics_doc(version) }
      end
    end
  end
end

RSpec.describe 'order IDs' do
  def client(**options)
    Epics::Client.new(File.open(File.join(File.dirname(__FILE__), 'fixtures', 'SIZBN001.key')),
                      'secret', 'https://example.com/ebics', 'SIZBN001', 'EBIX', 'EBICS', **options)
  end

  describe 'accepted input' do
    it 'defaults to A000' do
      expect(client.current_order_id).to eq(Epics::Client::MIN_ORDER_ID)
    end

    it 'accepts the integer form' do
      expect(client(order_id: 500_000).current_order_id).to eq(500_000)
    end

    # The bank and the initialisation letter both show the protocol form, so a caller
    # persisting what it saw hands back a string.
    it 'accepts the protocol form' do
      expect(client(order_id: 'A000').current_order_id).to eq(Epics::Client::MIN_ORDER_ID)
    end

    it 'round-trips the protocol form' do
      expect(client(order_id: 'B7Z9').current_order_id.to_s(36).upcase).to eq('B7Z9')
    end
  end

  describe 'rejected input' do
    # Anything below A000 renders as e.g. "0002", violating [A-Z][A-Z0-9]{3}.
    it 'rejects a value below A000' do
      expect { client(order_id: 2) }.to raise_error(ArgumentError, /between A000 and ZZZZ/)
    end

    it 'rejects a value above ZZZZ' do
      expect { client(order_id: 1_679_616) }.to raise_error(ArgumentError, /between A000 and ZZZZ/)
    end

    it 'rejects a string that is not a valid order id' do
      expect { client(order_id: 'nope!') }.to raise_error(ArgumentError, /between A000 and ZZZZ/)
    end
  end

  describe '#next_order_id' do
    it 'increments' do
      c = client
      expect { c.next_order_id }.to change(c, :current_order_id).by(1)
    end

    it 'raises at the end of the range' do
      c = client(order_id: Epics::Client::MAX_ORDER_ID)

      expect { c.next_order_id }.to raise_error(/overflow/)
    end
  end

  describe 'rendering' do
    it 'renders every accepted value as a valid OrderID' do
      [Epics::Client::MIN_ORDER_ID, 500_000, Epics::Client::MAX_ORDER_ID].each do |id|
        builder = nil
        Epics::Builders::OrderDetailsBuilder::V2.new { |b| builder = b.add_order_id(id) }

        expect(builder.doc.at_xpath('//OrderID').text).to match(/\A[A-Z][A-Z0-9]{3}\z/)
      end
    end
  end
end

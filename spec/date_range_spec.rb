RSpec.describe 'DateRange in order params' do
  let(:builder_class) { Epics::Builders::OrderDetailsBuilder::V2 }

  def order_details(start_date, end_date)
    builder = nil
    builder_class.new { |b| builder = b.add_standard_order_params(start_date, end_date) }
    Nokogiri::XML(builder.doc.to_xml)
  end

  it 'omits DateRange when neither bound is given' do
    expect(order_details(nil, nil).at_xpath('//DateRange')).to be_nil
  end

  it 'emits both bounds when given' do
    xml = order_details(Date.new(2026, 1, 1), Date.new(2026, 1, 31))

    expect(xml.at_xpath('//Start').text).to eq('2026-01-01')
    expect(xml.at_xpath('//End').text).to eq('2026-01-31')
  end

  # Start and End are both mandatory within DateRange, so one bound cannot be rendered.
  it 'raises when only a start date is given' do
    expect { order_details(Date.new(2026, 1, 1), nil) }
      .to raise_error(ArgumentError, /both a start and an end date/)
  end

  it 'raises when only an end date is given' do
    expect { order_details(nil, Date.new(2026, 1, 31)) }
      .to raise_error(ArgumentError, /both a start and an end date/)
  end

  # Start and End are xs:date -- an offset-bearing xs:dateTime is rejected by the bank.
  it 'renders Time as a plain date' do
    xml = order_details(Time.new(2026, 1, 1, 16, 53, 7), Time.new(2026, 1, 31, 8, 0, 0))

    expect(xml.at_xpath('//Start').text).to eq('2026-01-01')
    expect(xml.at_xpath('//End').text).to eq('2026-01-31')
  end

  it 'renders DateTime as a plain date' do
    xml = order_details(DateTime.new(2026, 1, 1, 16, 53, 7), DateTime.new(2026, 1, 31, 8, 0, 0))

    expect(xml.at_xpath('//Start').text).to eq('2026-01-01')
    expect(xml.at_xpath('//End').text).to eq('2026-01-31')
  end
end

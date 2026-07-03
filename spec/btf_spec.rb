RSpec.describe Epics::BTF do
  it 'normalizes attributes into the service hash consumed by HeaderRequest' do
    btf = described_class.new(
      service_name: 'SCT', scope: 'DE', service_option: 'URG',
      container: 'ZIP', msg_name: 'pain.001', msg_version: '03', msg_variant: '001'
    )

    expect(btf.to_h).to eq(
      service_name: 'SCT',
      service_option: 'URG',
      scope: 'DE',
      container: 'ZIP',
      msg_name: { name: 'pain.001', version: '03', variant: '001', format: nil }
    )
  end
end

RSpec.describe Epics::BtfMapping do
  it 'maps a known upload code to a BTF' do
    btf = described_class.upload('CCT')
    expect(btf).to be_a(Epics::BTF)
    expect(btf.service_name).to eq('SCT')
    expect(btf.msg_name).to eq('pain.001')
  end

  it 'maps a known download code to a BTF' do
    btf = described_class.download('C53')
    expect(btf.service_name).to eq('EOP')
    expect(btf.container).to eq('ZIP')
    expect(btf.msg_name).to eq('camt.053')
  end

  it 'raises a helpful error for unmapped codes' do
    expect { described_class.upload('ZZZ') }.to raise_error(ArgumentError, /raw/)
  end
end

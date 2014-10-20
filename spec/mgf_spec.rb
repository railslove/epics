RSpec.describe Epics::MGF1 do

  describe '#generate' do
    it { expect(subject.generate('foo', 0)).to eq('')}
    it { expect(subject.generate('bar', 1)).to eq('8')}
    it { expect(subject.generate('noIdea', 2).bytes.to_a).to eq([86, 174])}
    it { expect(subject.generate('What', 4).bytes.to_a).to eq([238, 183, 195, 188])}
    it { expect(subject.generate('ImDoing', 8).bytes.to_a).to eq([134, 205, 115, 236, 187, 67, 223, 2])}
    it { expect { subject.generate('seed', 137438953473) }.to raise_error(ArgumentError, 'mask too long') }
  end

  describe '#i2osp' do
    it { expect(subject.i2osp(1, 1).bytes.to_a).to eq([1])}
    it { expect(subject.i2osp(1, 2).bytes.to_a).to eq([0, 1])}
    it { expect(subject.i2osp(1, 3).bytes.to_a).to eq([0, 0, 1])}
    it { expect(subject.i2osp(2, 1).bytes.to_a).to eq([2])}
    it { expect(subject.i2osp(4, 4).bytes.to_a).to eq([0, 0, 0, 4])}
    it { expect { subject.i2osp(256, 1) }.to raise_error(ArgumentError, 'integer too large') }
  end

  describe '#divceil' do
    it { expect(subject.divceil(1, 1)).to eq(1) }
    it { expect(subject.divceil(8, 2)).to eq(4) }
    it { expect(subject.divceil(32, 4)).to eq(8) }
    it { expect(subject.divceil(140, 21)).to eq(7) }
    it { expect(subject.divceil(987654321, 123456789)).to eq(9) }
  end

  describe '#xor' do
    it { expect(subject.xor('a', 'a').bytes.to_a).to eq([0]) }
    it { expect(subject.xor('a', 'b').bytes.to_a).to eq([3]) }
    it { expect(subject.xor('foo', 'bar').bytes.to_a).to eq([4, 14, 29]) }
    it { expect(subject.xor('encyclopedia', 'aidepolcycne').bytes.to_a).to eq([4, 7, 7, 28, 19, 3, 3, 19, 28, 7, 7, 4]) }
    it { expect { subject.xor('to raise', 'or not') }.to raise_error(ArgumentError, 'different length for a and b') }
  end
end

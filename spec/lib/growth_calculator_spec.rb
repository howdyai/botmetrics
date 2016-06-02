RSpec.describe GrowthCalculator do
  describe '#call' do
    let(:values) { [3, 9, 81] }

    def result
      described_class.new(values, position).call
    end

    context 'arbitrary position' do
      let(:position) { 1 }

      it '[3*, 9*, 81] => (9-3)÷3 => 2' do
        expect(result).to eq 2.0
      end
    end

    context 'excludes last one' do
      let(:position) { -2 }

      it '[3*, 9*, 81] => (9-3)÷3 => 2' do
        expect(result).to eq 2.0
      end
    end

    context 'not excludes last one' do
      let(:position) { -1 }

      it '[3, 9*, 81*] => (81-9)÷9 => 2' do
        expect(result).to eq 8.0
      end
    end
  end
end

RSpec.describe GetStartEnd do
  describe '#call' do
    before { travel_to Time.new(2016, 5, 1) }

    it 'returns six days ago and end of today if no arguments given' do
      result = described_class.new(nil, nil).call

      start_time = (Time.current - 6.days).in_time_zone('UTC')
      end_time = (start_time + 6.days).in_time_zone('UTC')

      expect(result).to match_array([start_time.beginning_of_day, end_time.end_of_day])
    end

    after { travel_back }
  end
end

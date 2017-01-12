RSpec.describe GetStartEnd do
  describe '#call' do
    before { Timecop.travel Time.new(2016, 5, 16) }
    after { Timecop.return }

    it 'returns six days ago and end of today if no arguments given' do
      result = described_class.new(nil, nil).call

      start_time = (Time.current - 6.days).in_time_zone('UTC')
      end_time = (start_time + 6.days).in_time_zone('UTC')

      expect(result).to match_array([start_time.beginning_of_day, end_time.end_of_day])
    end

    it 'respects user time zone' do
      user_time_zone = 'Pacific Time (US & Canada)'
      result = described_class.new(nil, nil, user_time_zone).call

      start_time = (Time.current - 6.days).in_time_zone(user_time_zone)
      end_time = (start_time + 6.days).in_time_zone(user_time_zone)

      expect(result).to match_array([start_time.beginning_of_day, end_time.end_of_day])
    end

    it 'respects passed in time' do
      start_time = Time.new(2016, 5, 1)
      end_time = Time.new(2016, 5, 14)
      result = described_class.new(start_time, end_time).call

      start_time = start_time.in_time_zone('UTC')
      end_time = end_time.in_time_zone('UTC')

      expect(result).to match_array([start_time.beginning_of_day, end_time.end_of_day])
    end
  end
end

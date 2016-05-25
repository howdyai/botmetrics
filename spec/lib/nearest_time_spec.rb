RSpec.describe NearestTime do
  describe 'round' do
    nearest_times =
      [
        [Time.parse('2016-05-15 06:01:00 UTC'), 30.minutes, '2016-05-15 06:00:00 UTC'],
        [Time.parse('2016-05-15 06:31:00 UTC'), 30.minutes, '2016-05-15 06:30:00 UTC'],
        [Time.parse('2016-05-15 06:15:00 UTC'), 30.minutes, '2016-05-15 06:00:00 UTC'],
        [Time.parse('2016-05-15 06:45:00 UTC'), 30.minutes, '2016-05-15 06:30:00 UTC']
      ]

    nearest_times.each do |current_time, granularity, expected|
      it "rounds #{current_time} to #{expected}" do
        new_time = NearestTime.round(current_time, granularity)

        expect(new_time.to_s).to eq expected
      end
    end
  end
end

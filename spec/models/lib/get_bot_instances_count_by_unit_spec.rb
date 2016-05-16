RSpec.describe GetBotInstancesCountByUnit do
  describe '#call' do
    context 'day' do
      let(:unit) { 'day' }

      it 'works' do
        travel_to Time.current do
          create :bot_instance
          create :bot_instance, created_at: Time.current + 6.days

          create :bot_instance, created_at: Time.current.yesterday
          create :bot_instance, created_at: Time.current + 7.days

          result = begin
            GetBotInstancesCountByUnit.new(
              unit, BotInstance.all,
              start_time: Time.current, end_time: Time.current + 6.days,
              user_time_zone: 'UTC'
            ).call
          end

          expect(result.values).to match_array [1, 0, 0, 0, 0, 0, 1]
        end
      end
    end
  end
end

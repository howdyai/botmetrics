RSpec.describe FilterBotUsersService do
  describe '#scope' do
    let!(:user)       { create(:user) }
    let!(:bot)        { create(:bot) }
    let!(:instance_1) { create(:bot_instance, :with_attributes, uid: '123', bot: bot, state: 'enabled') }

    let!(:bot_user_1) { create(:bot_user, bot_instance: instance_1, user_attributes: { nickname: 'john', email: 'john@example.com' }) }
    let!(:bot_user_2) { create(:bot_user, bot_instance: instance_1, user_attributes: { nickname: 'sean', email: 'sean@example.com' }) }
    let!(:bot_user_3) { create(:bot_user, bot_instance: instance_1, user_attributes: { nickname: 'mike', email: 'mike@example.com' }) }

    ##### These do not appear - START
    let!(:instance_2) { create(:bot_instance, :with_attributes, uid: '456', bot: bot, state: 'pending') }

    let!(:bot_user_4) { create(:bot_user, bot_instance: instance_2, user_attributes: { nickname: 'johny', email: 'johny@example.com' }) }
    let!(:bot_user_5) { create(:bot_user, bot_instance: instance_2, user_attributes: { nickname: 'seany', email: 'seany@example.com' }) }
    let!(:bot_user_6) { create(:bot_user, bot_instance: instance_2, user_attributes: { nickname: 'mikey', email: 'mikey@example.com' }) }
    ##### These do not appear - END

    let(:service)   { FilterBotUsersService.new(query_set) }
    let(:query_set) { QuerySet.new(bot: bot, instances_scope: :legit, time_zone: user.timezone, queries: queries)}

    context 'slack' do
      let(:provider) { 'slack' }

      context 'empty query' do
        let(:queries)   { [Query.new(provider: provider, field: :nickname, method: :contains, value: nil)] }

        it 'returns all' do
          expect(service.scope.map(&:id)).to eq [bot_user_1, bot_user_2, bot_user_3].map(&:id)
        end
      end

      context 'one query' do
        let(:queries)   { [Query.new(provider: provider, field: :nickname, method: :contains, value: 'sean')] }

        it 'returns filtered' do
          expect(service.scope.map(&:id)).to eq [bot_user_2].map(&:id)
        end
      end

      context 'many queries' do
        let(:queries) do
          [
            Query.new(provider: provider, field: :nickname, method: :contains, value: 'mike'),
            Query.new(provider: provider, field: :email,    method: :contains, value: 'example')
          ]
        end

        it 'returns filtered' do
          expect(service.scope.map(&:id)).to eq [bot_user_3].map(&:id)
        end
      end

      context 'datetime queries' do
        context 'interacted_at' do
          let(:queries) do
            [
              Query.new(
                provider: provider, field: :interacted_at, method: :between,
                min_value: 4.days.ago, max_value: 2.days.ago
              )
            ]
          end

          it 'returns filtered' do
            create(:messages_to_bot_event, bot_instance_id: instance_1.id, bot_user_id: bot_user_1.id, created_at: 3.days.ago)

            expect(service.scope.map(&:id)).to match_array [user.id]
          end
        end

        context 'user_created_at' do
          let(:queries) do
            [
              Query.new(
                provider: provider, field: :user_created_at, method: :between,
                min_value: 8.days.ago, max_value: 6.days.ago
              )
            ]
          end

          it 'returns filtered' do
            one_week_user = create(:bot_user, created_at: 7.days.ago, bot_instance: instance_1)

            expect(service.scope.map(&:id)).to match_array [one_week_user.id]
          end
        end

        # Since we are sorting via arrays now, we don't really need this
        #
        # context 'sort' do
        #   let(:query_set) { QuerySet.new(bot: bot, instances_scope: :legit, time_zone: user.timezone, queries: queries)}
        #
        #   def exercise
        #     FilterBotUsersService.new(query_set).scope
        #   end
        #
        #   context 'need to sort' do
        #     let(:queries) { [Query.new(provider: provider, field: :nickname, method: :contains, value: 'sean')] }
        #
        #     before do
        #       create(:messages_to_bot_event, bot_instance_id: instance_1.id, bot_user_id: bot_user_2.id, created_at: 3.days.ago)
        #     end
        #
        #     it 'invokes BotUser.order_by_last_event_at' do
        #       allow(BotUser).to receive(:order_by_last_event_at) { double(includes: true) }
        #
        #       exercise
        #
        #       expect(BotUser).to have_received(:order_by_last_event_at)
        #     end
        #   end
        #
        #   context 'no need to sort for interacted_at between' do
        #     let(:queries) { [Query.new(provider: provider, field: :interacted_at, method: :between, min_value: 4.days.ago, max_value: 2.days.ago)] }
        #
        #     before do
        #       create(:messages_to_bot_event, bot_instance_id: instance_1.id, bot_user_id: bot_user_1.id, created_at: 3.days.ago)
        #     end
        #
        #     it 'returns' do
        #       expect(BotUser).to_not receive(:order_by_last_event_at)
        #
        #       exercise
        #     end
        #   end
        #
        #   context 'no need to sort for interacted at ago lesser than' do
        #     let(:queries) { [Query.new(provider: provider, field: :interacted_at_ago, method: :lesser_than, value: 3.days.ago)] }
        #
        #     before do
        #       create(:messages_to_bot_event, bot_user_id: bot_user_1.id, created_at: 2.days.ago)
        #     end
        #
        #     it 'returns' do
        #       expect(BotUser).to_not receive(:order_by_last_event_at)
        #
        #       exercise
        #     end
        #   end
        #
        #   context 'no need to sort for interacted at ago greater than' do
        #     let(:queries) { [Query.new(provider: provider, field: :interacted_at_ago, method: :greater_than, value: "3")] }
        #
        #     before do
        #       travel_to Time.current
        #       create(:messages_to_bot_event, bot_user_id: bot_user_1.id, created_at: 4.days.ago)
        #     end
        #
        #     it 'returns' do
        #       expect(BotUser).to_not receive(:order_by_last_event_at)
        #
        #       exercise
        #     end
        #   end
        # end
      end
    end
  end
end

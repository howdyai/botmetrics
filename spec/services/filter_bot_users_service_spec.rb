RSpec.describe FilterBotUsersService do
  describe '#scope' do
    let!(:user)       { create(:user) }
    let!(:bot)        { create(:bot) }
    let!(:instance_1) { create(:bot_instance, :with_attributes, uid: '123', bot: bot, state: 'enabled') }

    let!(:bot_user_1) { create(:bot_user, bot_instance: instance_1, user_attributes: { nickname: 'john', email: 'john@example.com' }, last_interacted_with_bot_at: 3.days.ago) }
    let!(:bot_user_2) { create(:bot_user, bot_instance: instance_1, user_attributes: { nickname: 'sean', email: 'sean@example.com' }) }
    let!(:bot_user_3) { create(:bot_user, bot_instance: instance_1, user_attributes: { nickname: 'mike', email: 'mike@example.com' }) }

    ##### These do not appear - START
    let!(:instance_2) { create(:bot_instance, :with_attributes, uid: '456', bot: bot, state: 'pending') }

    let!(:bot_user_4) { create(:bot_user, bot_instance: instance_2, user_attributes: { nickname: 'johny', email: 'johny@example.com' }) }
    let!(:bot_user_5) { create(:bot_user, bot_instance: instance_2, user_attributes: { nickname: 'seany', email: 'seany@example.com' }) }
    let!(:bot_user_6) { create(:bot_user, bot_instance: instance_2, user_attributes: { nickname: 'mikey', email: 'mikey@example.com' }) }
    ##### These do not appear - END

    let(:query_set) { create(:query_set, bot: bot, instances_scope: :legit, time_zone: user.timezone) }
    let(:service)   { FilterBotUsersService.new(query_set) }

    context 'slack' do
      let(:provider) { 'slack' }

      context 'empty query' do
        before do
          create(:query, provider: provider, field: :nickname, method: :contains, value: 'abc', query_set: query_set)
        end

        it 'returns nothing' do
          expect(service.scope.map(&:id)).to eq []
        end
      end

      context 'one query' do
        before do
          create(:query, provider: provider, field: :nickname, method: :contains, value: 'sean', query_set: query_set)
        end

        it 'returns filtered' do
          expect(service.scope.map(&:id)).to eq [bot_user_2].map(&:id)
        end
      end

      context 'many queries' do
        before do
          create(:query, provider: provider, field: :nickname, method: :contains, value: 'mike', query_set: query_set)
          create(:query, provider: provider, field: :email,    method: :contains, value: 'example', query_set: query_set)
        end

        it 'returns filtered' do
          expect(service.scope.map(&:id)).to eq [bot_user_3].map(&:id)
        end
      end

      context 'followed link queries' do
        let!(:user_1)  { create :bot_user, bot_instance: instance_1 }
        let!(:user_2)  { create :bot_user, bot_instance: instance_1 }
        let!(:event_1) { create :event, event_type: 'followed-link', event_attributes: { url: "https://host-#{SecureRandom.hex(8)}.google.com" }, bot_instance: instance_1, user: user_1 }
        let!(:event_2) { create :event, event_type: 'followed-link', event_attributes: { url: "https://host-#{SecureRandom.hex(8)}.google.com" }, bot_instance: instance_1, user: user_2 }

        context 'followed link equals' do
          before do
            @query = create(:query,
              provider: provider, field: "followed_link", method: :equals_to,
              value: event_1.event_attributes['url'],
              query_set: query_set
            )
          end

          it 'returns filtered' do
            expect(service.scope.map(&:id)).to match_array [user_1.id]
          end
        end

        context 'followed link contains' do
          before do
            @query = create(:query,
              provider: provider, field: "followed_link", method: :contains,
              value: 'google.com',
              query_set: query_set
            )
          end

          it 'returns filtered' do
            expect(service.scope.map(&:id)).to match_array [user_1.id, user_2.id]
          end
        end
      end

      context 'datetime queries' do
        context 'dashboard queries' do
          let!(:dashboard)      { create :dashboard, bot: bot, dashboard_type: 'custom', regex: 'abc' }

          before do
            @query = create(:query,
              provider: provider, field: "dashboard:#{dashboard.uid}", method: :between,
              min_value: 4.days.ago, max_value: 2.days.ago,
              query_set: query_set
            )
          end

          context 'custom dashboard' do
            let!(:included_user)  { create :bot_user, bot_instance: instance_1 }
            let!(:excluded_user)  { create :bot_user, bot_instance: instance_1 }
            let!(:event_1)        { create :event, created_at: 3.days.ago, user: included_user }
            let!(:event_2)        { create :event, created_at: 5.days.ago, user: excluded_user }
            let!(:de1)            { create :dashboard_event, dashboard: dashboard, event: event_1 }
            let!(:de2)            { create :dashboard_event, dashboard: dashboard, event: event_2 }

            it 'returns filtered' do
              RolledupEventQueue.flush!
              expect(service.scope.map(&:id)).to match_array [included_user.id]
            end
          end

          context 'image dashboard' do
            context 'facebook' do
              let!(:included_user)  { create :bot_user, bot_instance: instance_1 }
              let!(:excluded_user)  { create :bot_user, bot_instance: instance_1 }

              before do
                dashboard.update_attributes(provider: 'facebook', dashboard_type: 'image-uploaded', event_type: 'message:image-uploaded')
                create :facebook_image_event, bot_instance: instance_1, created_at: 3.days.ago, user: included_user
                create :facebook_image_event, bot_instance: instance_1, created_at: 5.days.ago, user: excluded_user

                @query.update_attribute(:provider, 'facebook')
                RolledupEventQueue.flush!
              end

              it 'returns filtered' do
                expect(service.scope.map(&:id)).to match_array [included_user.id]
              end
            end

            context 'kik' do
              let!(:included_user)  { create :bot_user, bot_instance: instance_1 }
              let!(:excluded_user)  { create :bot_user, bot_instance: instance_1 }

              before do
                dashboard.update_attributes(provider: 'kik', dashboard_type: 'image-uploaded', event_type: 'message:image-uploaded')
                create :kik_image_event, bot_instance: instance_1, created_at: 3.days.ago, user: included_user
                create :kik_image_event, bot_instance: instance_1, created_at: 5.days.ago, user: excluded_user
                @query.update_attribute(:provider, 'kik')

                RolledupEventQueue.flush!
              end

              it 'returns filtered' do
                expect(service.scope.map(&:id)).to match_array [included_user.id]
              end
            end
          end
        end

        context 'interacted_at' do
          before do
            create(:query,
              provider: provider, field: :interacted_at, method: :between,
              min_value: 4.days.ago, max_value: 2.days.ago,
              query_set: query_set
            )
          end

          it 'returns filtered' do
            expect(service.scope.map(&:id)).to match_array [user.id]
          end
        end

        context 'user_created_at' do
          before do
            create(:query,
              provider: provider, field: :user_created_at, method: :between,
              min_value: 8.days.ago, max_value: 6.days.ago,
              query_set: query_set
            )
          end

          it 'returns filtered' do
            one_week_user = create(:bot_user, created_at: 7.days.ago, bot_instance: instance_1)

            expect(service.scope.map(&:id)).to match_array [one_week_user.id]
          end
        end
      end
    end
  end
end

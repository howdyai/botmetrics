RSpec.describe BotUser do
  describe 'associations' do
    it { is_expected.to belong_to :bot_instance }
    it { is_expected.to have_many :events }
  end

  describe 'validations' do
    subject { create :bot_user }

    it { is_expected.to validate_presence_of :uid }
    it { is_expected.to validate_presence_of :provider }
    it { is_expected.to validate_presence_of :bot_instance_id }
    it { is_expected.to validate_presence_of :membership_type }
    it { is_expected.to validate_uniqueness_of(:uid).scoped_to(:bot_instance_id) }

    it { is_expected.to allow_value('slack').for(:provider) }
    it { is_expected.to allow_value('kik').for(:provider) }
    it { is_expected.to allow_value('facebook').for(:provider) }
    it { is_expected.to allow_value('telegram').for(:provider) }
    it { is_expected.to_not allow_value('test').for(:provider) }
  end

  context 'scopes' do
    let!(:query)      { create(:query) }
    let!(:user)       { create(:user) }
    let!(:bot)        { create(:bot) }
    let!(:instance) { create(:bot_instance, :with_attributes, uid: '123', bot: bot) }

    let!(:bot_user_1) { create(:bot_user, bot_instance: instance, user_attributes: { nickname: 'john', email: 'john@example.com' }, last_interacted_with_bot_at: 5.days.ago, bot_interaction_count: 1) }
    let!(:bot_user_2) { create(:bot_user, bot_instance: instance, user_attributes: { nickname: 'sean', email: 'sean@example.com' }, last_interacted_with_bot_at: 2.days.ago, bot_interaction_count: 2) }

    describe '#user_attributes_eq' do
      it { expect(BotUser.user_attributes_eq(:nickname, 'john')).to eq [bot_user_1] }
    end

    describe '#user_attributes_contains' do
      it { expect(BotUser.user_attributes_cont(:nickname, 'an')).to eq [bot_user_2] }
    end

    describe '#interaction_count_eq' do
      it { expect(BotUser.interaction_count_eq(1)).to eq [bot_user_1] }
      it { expect(BotUser.interaction_count_eq(2)).to eq [bot_user_2] }
    end

    describe '#interaction_count_gt' do
      it { expect(BotUser.interaction_count_gt(1)).to eq [bot_user_2] }
      it { expect(BotUser.interaction_count_gt(2)).to eq [] }
    end

    describe '#interaction_count_betw' do
      it { expect(BotUser.interaction_count_betw(0, 1)).to eq [bot_user_1] }
      it { expect(BotUser.interaction_count_betw(0, 5)).to eq [bot_user_1, bot_user_2] }
    end

    describe '.user_signed_up_betw' do
      let(:one_week_user) { create(:bot_user, created_at: 7.days.ago) }
      it { expect(BotUser.user_signed_up_betw(query, 8.days.ago, 5.days.ago)).to eq [one_week_user] }
    end

    describe '.user_signed_up_gt' do
      let(:one_week_user) { create(:bot_user, created_at: 7.days.ago) }

      it { expect(BotUser.user_signed_up_gt(query, 5.days.ago)).to eq [one_week_user] }
    end

    describe '.user_signed_up_lt' do
      let(:one_week_user) { create(:bot_user, created_at: 7.days.ago) }

      it { expect(BotUser.user_signed_up_lt(query, 5.days.ago)).to eq [bot_user_1, bot_user_2] }
    end
  end

  context 'followed link related scopes' do
    let!(:timezone)   { 'Pacific Time (US & Canada)' }
    let!(:bot)        { create :bot }
    let!(:instance)   { create :bot_instance, :with_attributes, uid: 'B123', bot: bot, state: 'enabled' }
    let!(:query_set)  { create :query_set, bot: bot }
    let!(:query)      { build  :query, query_set: query_set, field: "followed_link" }

    before  { Timecop.freeze Time.current.to_time.utc.beginning_of_hour }
    after   { Timecop.return }

    let!(:user_1) { create(:bot_user) }
    let!(:user_2) { create(:bot_user) }
    let!(:user_3) { create(:bot_user) }
    let!(:user_4) { create(:bot_user) }
    let!(:user_5) { create(:bot_user) }

    let!(:event_1) { create :event, event_type: 'followed-link', bot_instance: instance, event_attributes: { url: "https://host-#{user_1.id}.google.com" }, user: user_1 }
    let!(:event_2) { create :event, event_type: 'followed-link', bot_instance: instance, event_attributes: { url: "https://host-#{user_2.id}.google.com" }, user: user_2 }
    let!(:event_3) { create :event, event_type: 'followed-link', bot_instance: instance, event_attributes: { url: "https://host-#{user_3.id}.google.com" }, user: user_3 }
    let!(:event_4) { create :event, event_type: 'followed-link', bot_instance: instance, event_attributes: { url: "https://host-#{user_4.id}.google.com" }, user: user_4 }
    let!(:event_5) { create :event, event_type: 'followed-link', bot_instance: instance, event_attributes: { url: "https://host-#{user_5.id}.google.com" }, user: user_5 }

    let!(:event_not_included) { create :event, event_type: 'followed-link', user: create(:bot_user), event_attributes: { url: "https://host-#{user_5.id}.google.com" } }

    describe '.followed_link_eq' do
      it 'return users that clicked a given link (with full equality)' do
        result = BotUser.followed_link_eq(bot, "https://host-#{user_3.id}.google.com").map(&:id)
        expect(result).to match_array [user_3.id]
      end
    end

    describe '.followed_link_cont' do
      it 'return users that clicked a given link (with partial match)' do
        result = BotUser.followed_link_cont(bot, "google.com").map(&:id)
        expect(result).to match_array [user_1.id, user_2.id, user_3.id, user_4.id, user_5.id]
      end
    end
  end

  context 'dashboard related scopes' do
    let!(:timezone)   { 'Pacific Time (US & Canada)' }
    let!(:bot)        { create :bot }
    let!(:instance)   { create :bot_instance, bot: bot }
    let!(:dashboard)  { create :dashboard, bot: bot, dashboard_type: 'custom', regex: 'abc' }
    let!(:query_set)  { create :query_set, bot: bot }
    let!(:query)      { build  :query, query_set: query_set, field: "dashboard:#{dashboard.uid}" }

    before  { Timecop.freeze Time.current.to_time.utc.beginning_of_hour }
    after   { Timecop.return }

    let!(:user_1) { create(:bot_user) }
    let!(:user_2) { create(:bot_user) }
    let!(:user_3) { create(:bot_user) }
    let!(:user_4) { create(:bot_user) }
    let!(:user_5) { create(:bot_user) }

    describe 'custom dashboards' do
      let!(:event_1) { create :event, event_type: 'bot-installed', user: user_1, created_at: 1.day.ago }
      let!(:event_2) { create :event, event_type: 'bot-installed', user: user_2, created_at: 2.days.ago }
      let!(:event_3) { create :event, event_type: 'bot-installed', user: user_3, created_at: 3.days.ago }
      let!(:event_4) { create :event, event_type: 'bot-installed', user: user_4, created_at: 4.days.ago }
      let!(:event_5) { create :event, event_type: 'bot-installed', user: user_5, created_at: 5.days.ago }

      let!(:dashboard_event_1) { create :dashboard_event, dashboard: dashboard, event: event_1 }
      let!(:dashboard_event_2) { create :dashboard_event, dashboard: dashboard, event: event_2 }
      let!(:dashboard_event_3) { create :dashboard_event, dashboard: dashboard, event: event_3 }
      let!(:dashboard_event_4) { create :dashboard_event, dashboard: dashboard, event: event_4 }
      let!(:dashboard_event_5) { create :dashboard_event, dashboard: dashboard, event: event_5 }

      before do
        RolledupEventQueue.flush!
      end

      describe '.dashboard_betw' do
        it 'return users that performed events connected to a given dashboard between the time range' do
          result = BotUser.dashboard_betw(query, 3.days.ago, 3.days.ago).map(&:id)

          expect(result).to match_array [user_3.id]
        end
      end

      describe '.dashboard_lt' do
        it 'return users that performed events connected to a given dashboard lesser than given days ago' do
          result = BotUser.dashboard_lt(query, 3.days.ago).map(&:id)

          expect(result).to match_array [user_1.id, user_2.id]
        end
      end

      describe '.dashboard_gt' do
        it 'return users that performed events connected to a given dashboard greater than given days ago' do
          result = BotUser.dashboard_gt(query, 3.days.ago).map(&:id)

          expect(result).to match_array [user_4.id, user_5.id]
        end
      end
    end

    describe 'image events' do
      context 'facebook' do
        before do
          dashboard.update_attributes(provider: 'facebook', dashboard_type: 'image-uploaded', event_type: 'message:image-uploaded')
          create :facebook_image_event, bot_instance: instance, user: user_1, created_at: 1.day.ago
          create :facebook_image_event, bot_instance: instance, user: user_2, created_at: 2.days.ago
          create :facebook_image_event, bot_instance: instance, user: user_3, created_at: 3.days.ago
          create :facebook_image_event, bot_instance: instance, user: user_4, created_at: 4.days.ago
          create :facebook_image_event, bot_instance: instance, user: user_5, created_at: 5.days.ago

          RolledupEventQueue.flush!
        end

        describe '.dashboard_betw' do
          it 'return users that performed events connected to a given dashboard between the time range' do
            result = BotUser.dashboard_betw(query, 3.days.ago, 3.days.ago).map(&:id)

            expect(result).to match_array [user_3.id]
          end
        end

        describe '.dashboard_lt' do
          it 'return users that performed events connected to a given dashboard lesser than given days ago' do
            result = BotUser.dashboard_lt(query, 3.days.ago).map(&:id)

            expect(result).to match_array [user_1.id, user_2.id]
          end
        end

        describe '.dashboard_gt' do
          it 'return users that performed events connected to a given dashboard greater than given days ago' do
            result = BotUser.dashboard_gt(query, 3.days.ago).map(&:id)

            expect(result).to match_array [user_4.id, user_5.id]
          end
        end
      end

      context 'kik' do
        before do
          dashboard.update_attributes(provider: 'kik', dashboard_type: 'image-uploaded', event_type: 'message:image-uploaded')

          create :kik_image_event, bot_instance: instance, user: user_1, created_at: 1.day.ago
          create :kik_image_event, bot_instance: instance, user: user_2, created_at: 2.days.ago
          create :kik_image_event, bot_instance: instance, user: user_3, created_at: 3.days.ago
          create :kik_image_event, bot_instance: instance, user: user_4, created_at: 4.days.ago
          create :kik_image_event, bot_instance: instance, user: user_5, created_at: 5.days.ago

          RolledupEventQueue.flush!
        end

        describe '.dashboard_betw' do
          it 'return users that performed events connected to a given dashboard between the time range' do
            result = BotUser.dashboard_betw(query, 3.days.ago, 3.days.ago).map(&:id)

            expect(result).to match_array [user_3.id]
          end
        end

        describe '.dashboard_lt' do
          it 'return users that performed events connected to a given dashboard lesser than given days ago' do
            result = BotUser.dashboard_lt(query, 3.days.ago).map(&:id)

            expect(result).to match_array [user_1.id, user_2.id]
          end
        end

        describe '.dashboard_gt' do
          it 'return users that performed events connected to a given dashboard greater than given days ago' do
            result = BotUser.dashboard_gt(query, 3.days.ago).map(&:id)

            expect(result).to match_array [user_4.id, user_5.id]
          end
        end
      end
    end
  end

  context 'interacted related scopes' do
    let(:timezone) { 'Pacific Time (US & Canada)' }
    let(:query)    { create :query }

    before { Timecop.freeze Time.current.to_time.utc }
    after { Timecop.return }

    let!(:user_1_id) { create(:bot_user, last_interacted_with_bot_at: 1.days.ago).id }
    let!(:user_2_id) { create(:bot_user, last_interacted_with_bot_at: 2.days.ago).id }
    let!(:user_3_id) { create(:bot_user, last_interacted_with_bot_at: 3.days.ago).id }
    let!(:user_4_id) { create(:bot_user, last_interacted_with_bot_at: 4.days.ago).id }
    let!(:user_5_id) { create(:bot_user, last_interacted_with_bot_at: 5.days.ago).id }

    describe '.interacted_at_betw' do
      it 'return users that interacted ago is within given range' do
        result = BotUser.interacted_at_betw(query, 3.days.ago - 1.second, 3.days.ago + 1.second).map(&:id)

        expect(result).to match_array [user_3_id]
      end
    end

    describe '.interacted_at_lt' do
      it 'return users that interacted is lesser than given days ago' do
        result = BotUser.interacted_at_lt(query, 3.days.ago).map(&:id)

        expect(result).to match_array [user_1_id, user_2_id]
      end
    end

    describe '.interacted_at_gt' do
      it 'return users that interacted is greater than given days ago' do
        result = BotUser.interacted_at_gt(query, 3.days.ago).map(&:id)

        expect(result).to match_array [user_4_id, user_5_id]
      end
    end
  end

  context 'store accessors' do
    describe 'user_attributes' do
      it { expect(subject).to respond_to :nickname }
      it { expect(subject).to respond_to :email }
      it { expect(subject).to respond_to :full_name }
      it { expect(subject).to respond_to :first_name }
      it { expect(subject).to respond_to :last_name }
      it { expect(subject).to respond_to :gender }
    end
  end

  describe '.by_cohort' do
    let!(:bot) { create :bot, provider: 'slack' }
    let!(:bi1) { create :bot_instance, bot: bot, provider: 'slack' }
    let!(:bi2) { create :bot_instance, bot: bot, provider: 'slack' }
    let!(:dasboard) { create :dashboard, bot: bot, provider: 'facebook', dashboard_type: 'messages-to-bot', event_type: 'message' }

    context 'weekly retention' do
      before do
        Timecop.freeze Time.current.to_time.utc
        @start_time = 8.weeks.ago.beginning_of_week

        @users = []

        # Create users for 8 weeks, each week starts with 10 users
        count = 1

        9.times do |i|
          sub_users = []
          (10*count).times do
            sub_users << create(:bot_user, bot_instance: bi1, created_at: @start_time + i.weeks + 1.hour)
          end
          @users << sub_users
          count += 1
        end

        @users.each_with_index do |sub_users, index|
          # Every user is active in the first week
          sub_users.each do |user|
            create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: true, user: user, created_at: @start_time + index.weeks + 1.hour)
            create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: false, user: user, created_at: @start_time + index.weeks + 1.hour)
          end
          count = 1
          (index+1...9).each do |j|
            (0...sub_users.length-count).each do |idx|
              user = sub_users[idx]
              create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: true, user: user, created_at: @start_time + j.weeks + 1.hour)
              create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: false, user: user, created_at: @start_time + j.weeks + 1.hour)
            end
            count += 1
          end
        end

        RolledupEventQueue.flush!
      end

      after { Timecop.return }

      it 'should return the number of users per cohort' do
        expect(BotUser.by_cohort(bot, start_time: 8.weeks.ago)).to eql [10, 9, 8, 7, 6, 5, 4, 3, 2]
        expect(BotUser.by_cohort(bot, start_time: 7.weeks.ago)).to eql [20, 19, 18, 17, 16, 15, 14, 13]
        expect(BotUser.by_cohort(bot, start_time: 6.weeks.ago)).to eql [30, 29, 28, 27, 26, 25, 24]
      end
    end

    context 'daily retention' do
      before do
        Timecop.freeze Time.current.to_time.utc
        @start_time = 8.days.ago.beginning_of_day

        @users = []

        # Create users for 8 weeks, each week starts with 10 users
        count = 1

        9.times do |i|
          sub_users = []
          (10*count).times do
            sub_users << create(:bot_user, bot_instance: bi1, created_at: @start_time + i.days + 1.hour)
          end
          @users << sub_users
          count += 1
        end

        @users.each_with_index do |sub_users, index|
          # Every user is active in the first week
          sub_users.each do |user|
            create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: true, user: user, created_at: @start_time + index.days + 1.hour)
            create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: false, user: user, created_at: @start_time + index.days + 1.hour)
          end
          count = 1
          (index+1...9).each do |j|
            (0...sub_users.length-count).each do |idx|
              user = sub_users[idx]
              create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: true, user: user, created_at: @start_time + j.days + 1.hour)
              create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: false, user: user, created_at: @start_time + j.days + 1.hour)
            end
            count += 1
          end
        end

        RolledupEventQueue.flush!
      end

      after { Timecop.return }

      it 'should return the number of users per cohort' do
        expect(BotUser.by_cohort(bot, start_time: 8.days.ago, group_by: 'day')).to eql [10, 9, 8, 7, 6, 5, 4, 3, 2]
        expect(BotUser.by_cohort(bot, start_time: 7.days.ago, group_by: 'day')).to eql [20, 19, 18, 17, 16, 15, 14, 13]
        expect(BotUser.by_cohort(bot, start_time: 6.days.ago, group_by: 'day')).to eql [30, 29, 28, 27, 26, 25, 24]
      end
    end

    context 'monthly retention' do
      before do
        Timecop.freeze Time.current.to_time.utc
        @start_time = 8.months.ago.beginning_of_month

        @users = []

        # Create users for 8 weeks, each week starts with 10 users
        count = 1

        9.times do |i|
          sub_users = []
          (10*count).times do
            sub_users << create(:bot_user, bot_instance: bi1, created_at: @start_time + i.months + 1.hour)
          end
          @users << sub_users
          count += 1
        end

        @users.each_with_index do |sub_users, index|
          # Every user is active in the first week
          sub_users.each do |user|
            create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: true, user: user, created_at: @start_time + index.months + 1.hour)
            create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: false, user: user, created_at: @start_time + index.months + 1.hour)
          end
          count = 1
          (index+1...9).each do |j|
            (0...sub_users.length-count).each do |idx|
              user = sub_users[idx]
              create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: true, user: user, created_at: @start_time + j.months + 1.hour)
              create(:event, event_type: 'message', bot_instance: bi1, is_for_bot: false, user: user, created_at: @start_time + j.months + 1.hour)
            end
            count += 1
          end
        end

        RolledupEventQueue.flush!
      end

      after { Timecop.return }

      it 'should return the number of users per cohort' do
        expect(BotUser.by_cohort(bot, start_time: 8.months.ago, group_by: 'month')).to eql [10, 9, 8, 7, 6, 5, 4, 3, 2, 0]
        expect(BotUser.by_cohort(bot, start_time: 7.months.ago, group_by: 'month')).to eql [20, 19, 18, 17, 16, 15, 14, 13, 0]
        expect(BotUser.by_cohort(bot, start_time: 6.months.ago, group_by: 'month')).to eql [30, 29, 28, 27, 26, 25, 24, 0]
      end
    end
  end
end

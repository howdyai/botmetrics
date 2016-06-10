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
    let!(:user)       { create(:user) }
    let!(:bot)        { create(:bot) }
    let!(:instance) { create(:bot_instance, :with_attributes, uid: '123', bot: bot) }

    let!(:bot_user_1) { create(:bot_user, bot_instance: instance, user_attributes: { nickname: 'john', email: 'john@example.com' }) }
    let!(:bot_user_2) { create(:bot_user, bot_instance: instance, user_attributes: { nickname: 'sean', email: 'sean@example.com' }) }

    let!(:event_1) { create(:messages_to_bot_event, bot_instance: instance, bot_user_id: bot_user_1.id, created_at: 5.days.ago) }
    let!(:event_A) { create(:messages_to_bot_event, bot_instance: instance, bot_user_id: bot_user_2.id, created_at: 2.days.ago) }
    let!(:event_B) { create(:messages_to_bot_event, bot_instance: instance, bot_user_id: bot_user_2.id, created_at: 2.days.ago) }

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
      it { expect(BotUser.user_signed_up_betw(8.days.ago, 5.days.ago)).to eq [one_week_user] }
    end

    describe '#order_by_last_event_at' do
      it { expect(BotUser.order_by_last_event_at(BotUser.all)).to eq [bot_user_2, bot_user_1] }
    end
  end

  context 'interacted related scopes' do
    let(:timezone) { 'Pacific Time (US & Canada)' }

    def create_bot_user_with_event(days_ago:)
      create(:bot_user).tap do |bot_user|
        create(:messages_to_bot_event, bot_user_id: bot_user.id, created_at: days_ago)
      end.id
    end

    before { travel_to Time.current }
    after { travel_back }

    let!(:user_1_id) { create_bot_user_with_event(days_ago: 1.days.ago) }
    let!(:user_2_id) { create_bot_user_with_event(days_ago: 2.days.ago) }
    let!(:user_3_id) { create_bot_user_with_event(days_ago: 3.days.ago) }
    let!(:user_4_id) { create_bot_user_with_event(days_ago: 4.days.ago) }
    let!(:user_5_id) { create_bot_user_with_event(days_ago: 5.days.ago) }

    describe '.interacted_at_betw' do
      it 'return users that interacted ago is within given range' do
        result = BotUser.interacted_at_betw(3.days.ago - 1.second, 3.days.ago + 1.second).map(&:id)

        expect(result).to match_array [user_3_id]
      end
    end

    describe '.interacted_at_ago_lt' do
      it 'return users that interacted ago is lesser than given days ago' do
        result = BotUser.interacted_at_ago_lt(3.days.ago).map(&:id)

        expect(result).to match_array [user_1_id, user_2_id]
      end
    end

    describe '.interacted_at_ago_gt' do
      it 'return users that interacted ago is greater than given days ago' do
        result = BotUser.interacted_at_ago_gt(3.days.ago).map(&:id)

        expect(result).to match_array [user_4_id, user_5_id]
      end
    end
  end

  context 'store accessors' do
    describe 'user_attributes' do
      it { expect(subject).to respond_to :nickname }
      it { expect(subject).to respond_to :email }
      it { expect(subject).to respond_to :full_name }
    end
  end

  describe '.with_bot_instances' do
    let(:start_time) { Time.current.yesterday }
    let(:end_time)   { Time.current.tomorrow }

    it 'works' do
      bi = create :bot_instance
      bu = create :bot_user, bot_instance: bi
      create :bot_user

      users = BotUser.with_bot_instances(BotInstance.where(id: [bi.id]), start_time, end_time)

      expect(users.map(&:id)).to eq [bu.id]
    end
  end

  describe '.interacted_with' do
    let!(:bot) { create(:bot) }
    let!(:enabled) do
      create(
        :bot_instance, bot: bot, state: 'enabled', uid: rand(10000),
        instance_attributes: { team_id: 'T1', team_name: 'T1', team_url: 'T1'}
      )
    end
    let!(:disabled) do
      create(:bot_instance, bot: bot, state: 'disabled', uid: 'U123')
    end

    let(:bot_users) { create_list(:bot_user, 4) }

    def params
      { provider: 'slack', event_attributes: { channel: SecureRandom.hex(4), timestamp: Time.now.to_i + rand(100), reaction: 'OK'} }
    end

    def create_event(event_type, bot_instance, user, is_for_bot)
      create(:event, { event_type: event_type, bot_instance: bot_instance, user: user, is_for_bot: is_for_bot }.merge(params))
    end

    it 'finds users with message events for enabled bot instances' do
      create_event('message', enabled,  bot_users[0], true)
      create_event('message', enabled,  bot_users[0], true)

      create_event('message', enabled,  bot_users[1], false)
      create_event('message', disabled, bot_users[2], true)
      create_event('added_to_channel', enabled, bot_users[3], false)
      create_event('message_reaction', enabled, bot_users[3], true)

      expect(BotUser.interacted_with(bot)).to eq [bot_users[0].id]
    end
  end
end

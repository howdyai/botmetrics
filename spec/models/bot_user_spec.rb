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

  describe '#interacted_with' do
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
      { provider: 'slack', event_attributes: { channel: 'C', timestamp: Time.now.to_i + rand(100), reaction: 'OK'} }
    end

    it 'finds users with message events for enabled bot instances' do
      Event.create!({event_type: 'message', bot_instance: enabled, user: bot_users[0]}.merge(params))
      Event.create!({event_type: 'message', bot_instance: enabled, user: bot_users[0]}.merge(params))

      Event.create!({event_type: 'message', bot_instance: disabled,user: bot_users[1]}.merge(params))
      Event.create!({event_type: 'added_to_channel', bot_instance: enabled, user: bot_users[2]}.merge(params))
      Event.create!({event_type: 'message_reaction', bot_instance: disabled, user: bot_users[3]}.merge(params))

      expect(BotUser.interacted_with(bot)).to eq [1]
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
end

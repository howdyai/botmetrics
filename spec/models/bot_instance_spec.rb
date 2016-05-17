require 'rails_helper'

RSpec.describe BotInstance do
  describe 'associations' do
    it { is_expected.to belong_to :bot }
    it { is_expected.to have_many :users }
    it { is_expected.to have_many :events }
    it { is_expected.to have_many :messages }
  end

  describe 'validations' do
    subject { create :bot_instance }

    it { is_expected.to validate_presence_of :token }
    it { is_expected.to validate_presence_of :bot_id }
    it { is_expected.to validate_presence_of :provider }
    it { is_expected.to validate_uniqueness_of :token }

    it { is_expected.to allow_value('slack').for(:provider) }
    it { is_expected.to allow_value('kik').for(:provider) }
    it { is_expected.to allow_value('facebook').for(:provider) }
    it { is_expected.to allow_value('telegram').for(:provider) }
    it { is_expected.to_not allow_value('test').for(:provider) }

    it { is_expected.to allow_value('pending').for(:state) }
    it { is_expected.to allow_value('enabled').for(:state) }
    it { is_expected.to allow_value('disabled').for(:state) }
    it { is_expected.to_not allow_value('test').for(:state) }

    context 'team_id is not null' do
      let!(:bi) { build :bot_instance, uid: 'UNESTOR1', instance_attributes: { 'team_url': 'https://test.com', 'team_name': 'Dead Team'} }

      it "should be invalid if state = 'enabled' and team_id IS NULL" do
        bi.state = 'enabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:instance_attributes]).to eql ["team_id can't be blank"]
      end

      it "should be valid if state = 'enabled' and team_id IS NOT NULL" do
        bi.state = 'enabled'
        bi.instance_attributes['team_id'] = 'TDEADBEEF1'
        expect(bi).to be_valid
      end
    end

    context 'team_name is not null' do
      let!(:bi) { build :bot_instance, uid: 'UNESTOR1', instance_attributes: { 'team_url': 'https://test.com', 'team_id': 'TDEADBEEF1'} }

      it "should be invalid if state = 'enabled' and team_name IS NULL" do
        bi.state = 'enabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:instance_attributes]).to eql ["team_name can't be blank"]
      end

      it "should be valid if state = 'enabled' and team_name IS NOT NULL" do
        bi.state = 'enabled'
        bi.instance_attributes['team_name'] = 'Dead Team'
        expect(bi).to be_valid
      end
    end

    context 'team_url is not null' do
      let!(:bi) { build :bot_instance, uid: 'UNESTOR1', instance_attributes: { 'team_id': 'TDEADBEEF1', 'team_name': 'Dead Team'} }

      it "should be invalid if state = 'enabled' and team_url IS NULL" do
        bi.state = 'enabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:instance_attributes]).to eql ["team_url can't be blank"]
      end

      it "should be valid if state = 'enabled' and team_url IS NOT NULL" do
        bi.state = 'enabled'
        bi.instance_attributes['team_url'] = 'https://test.slack.com'
        expect(bi).to be_valid
      end
    end

    context 'conditional uid not null' do
      let!(:bi) { build :bot_instance, instance_attributes: { team_id: 'TDEADBEEF1', 'team_url': 'https://test.com', 'team_name': 'Dead Team'} }

      it "should be invalid if state = 'enabled' and uid IS NULL" do
        bi.state = 'enabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:uid]).to eql ["can't be blank"]
      end

      it "should be valid if state = 'enabled' and uid IS NOT NULL" do
        bi.state = 'enabled'
        bi.uid = 'udeadbeef1'
        expect(bi).to be_valid
      end

      it "should be valid if state = 'disabled' and uid IS NULL" do
        bi.state = 'disabled'
        expect(bi).to be_valid
      end
    end
  end

  describe '.with_new_bots' do
    let(:start_time) { Time.current }
    let(:end_time) { Time.current + 6.days }
    let(:bi) { create :bot_instance }
    let(:new_bi) { create :bot_instance, created_at: Time.current + 1.days }

    before do
      travel_to Time.new(2016, 05, 01)
      bi
      new_bi
      create :bot_instance, created_at: Time.current - 7.days
      create :bot_instance, created_at: Time.current + 7.days
    end
    after { travel_back }

    it 'returns instances within correct ranges and order by created at' do
      result = described_class.with_new_bots(start_time, end_time)

      expect(result.map(&:id)).to eq [new_bi.id, bi.id]
    end
  end

  describe '.with_disabled_bots' do
    def create_disabled_bots_event(bot_instance_id, creation_time = Time.current)
      Event.create(
        provider: 'slack',
        event_type: 'bot_disabled',
        bot_instance_id: bot_instance_id,
        created_at: creation_time
      )
    end

    it 'returns instances within correct ranges and order by last_event_at at' do
      bi1 = create :bot_instance
      bi2 = create :bot_instance

      create_disabled_bots_event bi1.id
      create_disabled_bots_event bi2.id, Time.current.yesterday

      associated_bot_instances_ids = BotInstance.ids

      result = described_class.with_disabled_bots(associated_bot_instances_ids)

      expect(result.map(&:id)).to eq [bi1.id, bi2.id]
    end
  end

  describe '.with_all_messages' do
    def create_all_message_event(bot_instance_id, bot_user_id, creation_time = Time.current)
      Event.create(
        event_type: 'message',
        is_from_bot: false,
        provider: 'slack',
        bot_instance_id: bot_instance_id,
        bot_user_id: bot_user_id,
        event_attributes: { channel: SecureRandom.hex(8), timestamp: Time.now.to_i },
        created_at: creation_time
      )
    end

    it 'returns instances within correct ranges and order by last_event_at at' do
      bi1 = create :bot_instance
      bi2 = create :bot_instance
      bu1 = create :bot_user, bot_instance: bi1
      bu2 = create :bot_user, bot_instance: bi2

      create_all_message_event(bi1.id, bu1.id)
      create_all_message_event(bi2.id, bu2.id, Time.current.yesterday)

      associated_bot_instances_ids = BotInstance.ids

      result = described_class.with_all_messages(associated_bot_instances_ids)

      expect(result.map(&:id)).to eq [bi1.id, bi2.id]
    end
  end

  describe '.with_messages_to_bot' do
    def create_messages_to_bot_event(bot_instance_id, bot_user_id, creation_time = Time.current)
      Event.create(
        event_type: 'message',
        is_for_bot: true,
        provider: 'slack',
        bot_instance_id: bot_instance_id,
        bot_user_id: bot_user_id,
        event_attributes: { channel: SecureRandom.hex(8), timestamp: Time.now.to_i },
        created_at: creation_time
      )
    end

    it 'returns instances within correct ranges and order by last_event_at at' do
      bi1 = create :bot_instance
      bi2 = create :bot_instance
      bu1 = create :bot_user, bot_instance: bi1
      bu2 = create :bot_user, bot_instance: bi2

      create_messages_to_bot_event(bi1.id, bu1.id)
      create_messages_to_bot_event(bi2.id, bu2.id, Time.current.yesterday)

      associated_bot_instances_ids = BotInstance.ids

      result = described_class.with_messages_to_bot(associated_bot_instances_ids)

      expect(result.map(&:id)).to eq [bi1.id, bi2.id]
    end
  end

  describe '.with_messages_from_bot' do
    def create_messages_from_bot_event(bot_instance_id, bot_user_id, creation_time = Time.current)
      Event.create(
        event_type: 'message',
        is_from_bot: true,
        provider: 'slack',
        bot_instance_id: bot_instance_id,
        bot_user_id: bot_user_id,
        event_attributes: { channel: SecureRandom.hex(8), timestamp: Time.now.to_i },
        created_at: creation_time
      )
    end

    it 'returns instances within correct ranges and order by last_event_at at' do
      bi1 = create :bot_instance
      bi2 = create :bot_instance
      bu1 = create :bot_user, bot_instance: bi1
      bu2 = create :bot_user, bot_instance: bi2

      create_messages_from_bot_event(bi1.id, bu1.id)
      create_messages_from_bot_event(bi2.id, bu2.id, Time.current.yesterday)

      associated_bot_instances_ids = BotInstance.ids

      result = described_class.with_messages_from_bot(associated_bot_instances_ids)

      expect(result.map(&:id)).to eq [bi1.id, bi2.id]
    end
  end
end

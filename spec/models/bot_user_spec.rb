require 'spec_helper'

RSpec.describe BotUser do
  describe 'validations' do
    subject { create :bot_user }

    it { should validate_presence_of :uid }
    it { should validate_presence_of :provider }
    it { should validate_presence_of :bot_instance_id }
    it { should validate_presence_of :membership_type }
    it { should validate_uniqueness_of(:uid).scoped_to(:bot_instance_id) }

    it { should allow_value('slack').for(:provider) }
    it { should allow_value('kik').for(:provider) }
    it { should allow_value('facebook').for(:provider) }
    it { should allow_value('telegram').for(:provider) }
    it { should_not allow_value('test').for(:provider) }
  end

  describe 'associations' do
    it { should belong_to :bot_instance }
  end

  describe '.with_bot_instances' do
    let(:start_time) { Time.current.yesterday }
    let(:end_time)   { Time.current.tomorrow }

    it 'works' do
      bi = create :bot_instance
      create :bot_user, bot_instance: bi
      create :bot_user

      users = BotUser.with_bot_instances(BotInstance.where(id: [bi.id]), start_time, end_time)

      expect(users.map(&:id)).to eq [1]
    end
  end
end

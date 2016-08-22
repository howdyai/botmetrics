require 'rails_helper'

RSpec.describe Dashboard, type: :model do
  describe 'validations' do
    subject { create :dashboard }

    it { should validate_presence_of :name }
    it { should validate_presence_of :bot_id }
    it { should validate_presence_of :user_id }
    it { should validate_presence_of :provider }
    it { should validate_uniqueness_of :uid }
    it { should validate_uniqueness_of(:name).scoped_to(:bot_id) }

    it { should allow_value('facebook').for(:provider) }
    it { should allow_value('kik').for(:provider) }
    it { should allow_value('slack').for(:provider) }
    it { should_not allow_value('abcdef').for(:provider) }
  end

  describe 'associations' do
    it { should belong_to :bot }
    it { should belong_to :user }
  end

  describe 'init!' do
    let!(:bot)       { create :bot, provider: 'slack' }
    let!(:dashboard) { create :dashboard, bot: bot }

    describe 'group_by is all-time' do
      before do
        dashboard.group_by = 'all-time'
      end

      describe 'bots-installed' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i3) { create :bot_instance }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-installed', provider: 'slack')
        end

        it 'should return all installed bots' do
          dashboard.init!
          expect(dashboard.data).to eql 2
        end
      end

      describe 'bots-uninstalled' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i3) { create :bot_instance }

        let!(:e1) { create :event, event_type: 'bot_disabled', bot_instance: i1 }
        let!(:e2) { create :event, event_type: 'bot_disabled', bot_instance: i1 }
        let!(:e3) { create :event, event_type: 'bot_disabled', bot_instance: i3 }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-uninstalled', provider: 'slack')
        end

        it 'should return all uninstalled bots' do
          dashboard.init!
          expect(dashboard.data).to eql 2
        end
      end

      describe 'new-users' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i3) { create :bot_instance }

        let!(:u1) { create :bot_user, :with_attributes, bot_instance: i1 }
        let!(:u2) { create :bot_user, :with_attributes, bot_instance: i1 }
        let!(:u3) { create :bot_user, :with_attributes, bot_instance: i1 }
        let!(:u4) { create :bot_user, :with_attributes, bot_instance: i2 }
        let!(:u5) { create :bot_user, :with_attributes, bot_instance: i2 }
        let!(:u6) { create :bot_user, :with_attributes, bot_instance: i3 }

        before do
          dashboard.update_attributes(dashboard_type: 'new-users', provider: 'slack')
        end

        it 'should return all users' do
          dashboard.init!
          expect(dashboard.data).to eql 5
        end
      end

      describe 'messages' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i3) { create :bot_instance }

        let!(:e1) { create :all_messages_event, bot_instance: i1 }
        let!(:e2) { create :all_messages_event, bot_instance: i1 }
        let!(:e3) { create :all_messages_event, bot_instance: i1 }
        let!(:e4) { create :all_messages_event, bot_instance: i2 }
        let!(:e5) { create :all_messages_event, bot_instance: i2 }
        let!(:e6) { create :all_messages_event, bot_instance: i3 }

        before do
          dashboard.update_attributes(dashboard_type: 'messages', provider: 'slack')
        end

        it 'should return all messages' do
          dashboard.init!
          expect(dashboard.data).to eql 5
        end
      end

      describe 'messages-to-bot' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i3) { create :bot_instance }

        let!(:e1) { create :messages_to_bot_event, bot_instance: i1 }
        let!(:e2) { create :messages_to_bot_event, bot_instance: i1 }
        let!(:e3) { create :messages_to_bot_event, bot_instance: i1 }
        let!(:e4) { create :messages_to_bot_event, bot_instance: i2 }
        let!(:e5) { create :messages_to_bot_event, bot_instance: i2 }
        let!(:e6) { create :messages_to_bot_event, bot_instance: i3 }

        before do
          dashboard.update_attributes(dashboard_type: 'messages-to-bot', provider: 'slack')
        end

        it 'should return all messages from the bot' do
          dashboard.init!
          expect(dashboard.data).to eql 5
        end
      end

      describe 'messages-from-bot' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled' }
        let!(:i3) { create :bot_instance }

        let!(:e1) { create :messages_from_bot_event, bot_instance: i1 }
        let!(:e2) { create :messages_from_bot_event, bot_instance: i1 }
        let!(:e3) { create :messages_from_bot_event, bot_instance: i1 }
        let!(:e4) { create :messages_from_bot_event, bot_instance: i2 }
        let!(:e5) { create :messages_from_bot_event, bot_instance: i2 }
        let!(:e6) { create :messages_from_bot_event, bot_instance: i3 }

        before do
          dashboard.update_attributes(dashboard_type: 'messages-from-bot', provider: 'slack')
        end

        it 'should return all messages from the bot' do
          dashboard.init!
          expect(dashboard.data).to eql 5
        end
      end
    end

    describe 'group_by is "today"' do
      before do
        dashboard.group_by = 'today'
        now = Time.now
        Timecop.freeze(2016, 8, 22, 10, 0, 0)
      end

      after do
        Timecop.return
      end

      describe 'bots-installed' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i9) { create :bot_instance }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-installed', provider: 'slack')
        end

        it 'should return all installed bots in the last week' do
          dashboard.init!
          expect(dashboard.data.size).to eql 7
          expect(dashboard.data.values).to eql [0, 0, 0, 0, 2, 3, 2]
          expect(dashboard.count).to eql 2
          expect((dashboard.growth * 100).round / 100.0).to eql -0.33
        end
      end

      describe 'bots-uninstalled' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i8) { create :bot_instance }

        let!(:e1) { create :event, event_type: 'bot_disabled', bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :event, event_type: 'bot_disabled', bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :event, event_type: 'bot_disabled', bot_instance: i3, created_at: 1.day.ago }
        let!(:e4) { create :event, event_type: 'bot_disabled', bot_instance: i4, created_at: 1.day.ago }
        let!(:e5) { create :event, event_type: 'bot_disabled', bot_instance: i5, created_at: 1.day.ago }
        let!(:e6) { create :event, event_type: 'bot_disabled', bot_instance: i6, created_at: 2.days.ago }
        let!(:e7) { create :event, event_type: 'bot_disabled', bot_instance: i7, created_at: 2.days.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-uninstalled', provider: 'slack')
        end

        it 'should return all uninstalled bots' do
          dashboard.init!
          expect(dashboard.data.size).to eql 7
          expect(dashboard.data.values).to eql [0, 0, 0, 0, 2, 3, 2]
          expect(dashboard.count).to eql 2
          expect((dashboard.growth * 100).round / 100.0).to eql -0.33
        end
      end

      describe 'new-users' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i8) { create :bot_instance }

        let!(:u1) { create :bot_user, :with_attributes, bot_instance: i1, created_at: Time.now }
        let!(:u2) { create :bot_user, :with_attributes, bot_instance: i1, created_at: Time.now }
        let!(:u3) { create :bot_user, :with_attributes, bot_instance: i1, created_at: Time.now }
        let!(:u4) { create :bot_user, :with_attributes, bot_instance: i2, created_at: 1.day.ago }
        let!(:u5) { create :bot_user, :with_attributes, bot_instance: i2, created_at: 2.days.ago }
        let!(:u6) { create :bot_user, :with_attributes, bot_instance: i3, created_at: 2.days.ago }
        let!(:u7) { create :bot_user, :with_attributes, bot_instance: i3, created_at: 2.days.ago }
        let!(:u8) { create :bot_user, :with_attributes, bot_instance: i3, created_at: 3.days.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'new-users', provider: 'slack')
        end

        it 'should return all users' do
          dashboard.init!
          expect(dashboard.data.size).to eql 7
          expect(dashboard.data.values).to eql [0, 0, 0, 1, 3, 1, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 2.0
        end
      end

      describe 'messages' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i8) { create :bot_instance }

        let!(:e1) { create :all_messages_event, bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :all_messages_event, bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :all_messages_event, bot_instance: i1, created_at: Time.now }
        let!(:e4) { create :all_messages_event, bot_instance: i2, created_at: 1.day.ago }
        let!(:e5) { create :all_messages_event, bot_instance: i2, created_at: 1.day.ago }
        let!(:e6) { create :all_messages_event, bot_instance: i3, created_at: 2.days.ago }
        let!(:e7) { create :all_messages_event, bot_instance: i3, created_at: 2.days.ago }
        let!(:e8) { create :all_messages_event, bot_instance: i3, created_at: 3.days.ago }
        let!(:e9) { create :all_messages_event, bot_instance: i3, created_at: 3.days.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'messages', provider: 'slack')
        end

        it 'should return all messages' do
          dashboard.init!
          expect(dashboard.data.size).to eql 7
          expect(dashboard.data.values).to eql [0, 0, 0, 2, 2, 2, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 0.5
        end
      end

      describe 'messages-to-bot' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i8) { create :bot_instance }

        let!(:e1) { create :messages_to_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :messages_to_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :messages_to_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e4) { create :messages_to_bot_event, bot_instance: i2, created_at: 1.day.ago }
        let!(:e5) { create :messages_to_bot_event, bot_instance: i2, created_at: 1.day.ago }
        let!(:e6) { create :messages_to_bot_event, bot_instance: i3, created_at: 2.days.ago }
        let!(:e7) { create :messages_to_bot_event, bot_instance: i3, created_at: 2.days.ago }
        let!(:e8) { create :messages_to_bot_event, bot_instance: i3, created_at: 3.days.ago }
        let!(:e9) { create :messages_to_bot_event, bot_instance: i3, created_at: 3.days.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'messages-to-bot', provider: 'slack')
        end

        it 'should return all messages' do
          dashboard.init!
          expect(dashboard.data.size).to eql 7
          expect(dashboard.data.values).to eql [0, 0, 0, 2, 2, 2, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 0.5
        end
      end

      describe 'messages-from-bot' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.days.ago }
        let!(:i8) { create :bot_instance }

        let!(:e1) { create :messages_from_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :messages_from_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :messages_from_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e4) { create :messages_from_bot_event, bot_instance: i2, created_at: 1.day.ago }
        let!(:e5) { create :messages_from_bot_event, bot_instance: i2, created_at: 1.day.ago }
        let!(:e6) { create :messages_from_bot_event, bot_instance: i3, created_at: 2.days.ago }
        let!(:e7) { create :messages_from_bot_event, bot_instance: i3, created_at: 2.days.ago }
        let!(:e8) { create :messages_from_bot_event, bot_instance: i3, created_at: 3.days.ago }
        let!(:e9) { create :messages_from_bot_event, bot_instance: i3, created_at: 3.days.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'messages-from-bot', provider: 'slack')
        end

        it 'should return all messages' do
          dashboard.init!
          expect(dashboard.data.size).to eql 7
          expect(dashboard.data.values).to eql [0, 0, 0, 2, 2, 2, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 0.5
        end
      end
    end

    describe 'group_by is "this-week"' do
      before do
        dashboard.group_by = 'this-week'
        now = Time.now
        # This date is a Monday so makes sure that everything works accordingly
        Timecop.freeze(2016, 8, 22, 10, 0, 0)
      end

      after do
        Timecop.return
      end

      describe 'bots-installed' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        # i3-i5 is Sunday
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i9) { create :bot_instance }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-installed', provider: 'slack')
        end

        it 'should return all installed bots in the last week' do
          dashboard.init!
          expect(dashboard.data.size).to eql 4
          expect(dashboard.data.values).to eql [0, 2, 3, 2]
          expect(dashboard.count).to eql 2
          expect((dashboard.growth * 100).round / 100.0).to eql -0.33
        end
      end

      describe 'bots-uninstalled' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i8) { create :bot_instance }

        let!(:e1) { create :event, event_type: 'bot_disabled', bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :event, event_type: 'bot_disabled', bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :event, event_type: 'bot_disabled', bot_instance: i3, created_at: 1.day.ago }
        let!(:e4) { create :event, event_type: 'bot_disabled', bot_instance: i4, created_at: 1.day.ago }
        let!(:e5) { create :event, event_type: 'bot_disabled', bot_instance: i5, created_at: 1.day.ago }
        let!(:e6) { create :event, event_type: 'bot_disabled', bot_instance: i6, created_at: 2.weeks.ago }
        let!(:e7) { create :event, event_type: 'bot_disabled', bot_instance: i7, created_at: 2.weeks.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-uninstalled', provider: 'slack')
        end

        it 'should return all uninstalled bots' do
          dashboard.init!
          expect(dashboard.data.size).to eql 4
          expect(dashboard.data.values).to eql [0, 2, 3, 2]
          expect(dashboard.count).to eql 2
          expect((dashboard.growth * 100).round / 100.0).to eql -0.33
        end
      end

      describe 'new-users' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i8) { create :bot_instance }

        let!(:u1) { create :bot_user, :with_attributes, bot_instance: i1, created_at: Time.now }
        let!(:u2) { create :bot_user, :with_attributes, bot_instance: i1, created_at: Time.now }
        let!(:u3) { create :bot_user, :with_attributes, bot_instance: i1, created_at: Time.now }
        let!(:u4) { create :bot_user, :with_attributes, bot_instance: i2, created_at: 1.day.ago }
        let!(:u5) { create :bot_user, :with_attributes, bot_instance: i2, created_at: 2.days.ago }
        let!(:u6) { create :bot_user, :with_attributes, bot_instance: i3, created_at: 2.weeks.ago }
        let!(:u7) { create :bot_user, :with_attributes, bot_instance: i3, created_at: 2.weeks.ago }
        let!(:u8) { create :bot_user, :with_attributes, bot_instance: i3, created_at: 3.weeks.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'new-users', provider: 'slack')
        end

        it 'should return all users' do
          dashboard.init!
          expect(dashboard.data.size).to eql 4
          expect(dashboard.data.values).to eql [1, 2, 2, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 0.5
        end
      end

      describe 'messages' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i8) { create :bot_instance }

        let!(:e1) { create :all_messages_event, bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :all_messages_event, bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :all_messages_event, bot_instance: i1, created_at: Time.now }
        let!(:e4) { create :all_messages_event, bot_instance: i2, created_at: 1.day.ago }
        let!(:e5) { create :all_messages_event, bot_instance: i2, created_at: 2.days.ago }
        let!(:e6) { create :all_messages_event, bot_instance: i3, created_at: 2.weeks.ago }
        let!(:e7) { create :all_messages_event, bot_instance: i3, created_at: 2.weeks.ago }
        let!(:e8) { create :all_messages_event, bot_instance: i3, created_at: 3.weeks.ago }
        let!(:e9) { create :all_messages_event, bot_instance: i3, created_at: 3.weeks.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'messages', provider: 'slack')
        end

        it 'should return all messages' do
          dashboard.init!
          expect(dashboard.data.size).to eql 4
          expect(dashboard.data.values).to eql [2, 2, 2, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 0.5
        end
      end

      describe 'messages-to-bot' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i8) { create :bot_instance }

        let!(:e1) { create :messages_to_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :messages_to_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :messages_to_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e4) { create :messages_to_bot_event, bot_instance: i2, created_at: 1.day.ago }
        let!(:e5) { create :messages_to_bot_event, bot_instance: i2, created_at: 2.days.ago }
        let!(:e6) { create :messages_to_bot_event, bot_instance: i3, created_at: 2.weeks.ago }
        let!(:e7) { create :messages_to_bot_event, bot_instance: i3, created_at: 2.weeks.ago }
        let!(:e8) { create :messages_to_bot_event, bot_instance: i3, created_at: 3.weeks.ago }
        let!(:e9) { create :messages_to_bot_event, bot_instance: i3, created_at: 3.weeks.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'messages-to-bot', provider: 'slack')
        end

        it 'should return all messages' do
          dashboard.init!
          expect(dashboard.data.size).to eql 4
          expect(dashboard.data.values).to eql [2, 2, 2, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 0.5
        end
      end

      describe 'messages-from-bot' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.day.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.weeks.ago }
        let!(:i8) { create :bot_instance }

        let!(:e1) { create :messages_from_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :messages_from_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :messages_from_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e4) { create :messages_from_bot_event, bot_instance: i2, created_at: 1.day.ago }
        let!(:e5) { create :messages_from_bot_event, bot_instance: i2, created_at: 2.days.ago }
        let!(:e6) { create :messages_from_bot_event, bot_instance: i3, created_at: 2.weeks.ago }
        let!(:e7) { create :messages_from_bot_event, bot_instance: i3, created_at: 2.weeks.ago }
        let!(:e8) { create :messages_from_bot_event, bot_instance: i3, created_at: 3.weeks.ago }
        let!(:e9) { create :messages_from_bot_event, bot_instance: i3, created_at: 3.weeks.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'messages-from-bot', provider: 'slack')
        end

        it 'should return all messages' do
          dashboard.init!
          expect(dashboard.data.size).to eql 4
          expect(dashboard.data.values).to eql [2, 2, 2, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 0.5
        end
      end
    end

    describe 'group_by is "this-month"' do
      before do
        dashboard.group_by = 'this-month'
        now = Time.now
        # This date is a Monday so makes sure that everything works accordingly
        Timecop.freeze(2016, 8, 22, 10, 0, 0)
      end

      after do
        Timecop.return
      end

      describe 'bots-installed' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        # i3-i5 is Sunday
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i9) { create :bot_instance }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-installed', provider: 'slack')
        end

        it 'should return all installed bots in the last week' do
          dashboard.init!
          expect(dashboard.data.size).to eql 12
          expect(dashboard.data.values).to eql [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 2]
          expect(dashboard.count).to eql 2
          expect((dashboard.growth * 100).round / 100.0).to eql -0.33
        end
      end

      describe 'bots-uninstalled' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        # i3-i5 is Sunday
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i9) { create :bot_instance }

        let!(:e1) { create :event, event_type: 'bot_disabled', bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :event, event_type: 'bot_disabled', bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :event, event_type: 'bot_disabled', bot_instance: i3, created_at: 1.month.ago }
        let!(:e4) { create :event, event_type: 'bot_disabled', bot_instance: i4, created_at: 1.month.ago }
        let!(:e5) { create :event, event_type: 'bot_disabled', bot_instance: i5, created_at: 1.month.ago }
        let!(:e6) { create :event, event_type: 'bot_disabled', bot_instance: i6, created_at: 2.months.ago }
        let!(:e7) { create :event, event_type: 'bot_disabled', bot_instance: i7, created_at: 2.months.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-uninstalled', provider: 'slack')
        end

        it 'should return all uninstalled bots' do
          dashboard.init!
          expect(dashboard.data.size).to eql 12
          expect(dashboard.data.values).to eql [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 2]
          expect(dashboard.count).to eql 2
          expect((dashboard.growth * 100).round / 100.0).to eql -0.33
        end
      end

      describe 'new-users' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i8) { create :bot_instance }

        let!(:u1) { create :bot_user, :with_attributes, bot_instance: i1, created_at: Time.now }
        let!(:u2) { create :bot_user, :with_attributes, bot_instance: i1, created_at: Time.now }
        let!(:u3) { create :bot_user, :with_attributes, bot_instance: i1, created_at: Time.now }
        let!(:u4) { create :bot_user, :with_attributes, bot_instance: i2, created_at: 1.month.ago }
        let!(:u5) { create :bot_user, :with_attributes, bot_instance: i2, created_at: 2.months.ago }
        let!(:u6) { create :bot_user, :with_attributes, bot_instance: i3, created_at: 2.months.ago }
        let!(:u7) { create :bot_user, :with_attributes, bot_instance: i3, created_at: 3.months.ago }
        let!(:u8) { create :bot_user, :with_attributes, bot_instance: i3, created_at: 3.months.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'new-users', provider: 'slack')
        end

        it 'should return all users' do
          dashboard.init!
          expect(dashboard.data.size).to eql 12
          expect(dashboard.data.values).to eql [0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 1, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 2.0
        end
      end

      describe 'messages' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i8) { create :bot_instance }

        let!(:e1) { create :all_messages_event, bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :all_messages_event, bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :all_messages_event, bot_instance: i1, created_at: Time.now }
        let!(:e4) { create :all_messages_event, bot_instance: i2, created_at: 1.month.ago }
        let!(:e5) { create :all_messages_event, bot_instance: i2, created_at: 2.months.ago }
        let!(:e6) { create :all_messages_event, bot_instance: i3, created_at: 2.months.ago }
        let!(:e7) { create :all_messages_event, bot_instance: i3, created_at: 3.months.ago }
        let!(:e8) { create :all_messages_event, bot_instance: i3, created_at: 4.months.ago }
        let!(:e9) { create :all_messages_event, bot_instance: i3, created_at: 4.months.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'messages', provider: 'slack')
        end

        it 'should return all messages' do
          dashboard.init!
          expect(dashboard.data.size).to eql 12
          expect(dashboard.data.values).to eql [0, 0, 0, 0, 0, 0, 0, 2, 1, 2, 1, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 2.0
        end
      end

      describe 'messages-to-bot' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i8) { create :bot_instance }

        let!(:e1) { create :messages_to_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :messages_to_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :messages_to_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e4) { create :messages_to_bot_event, bot_instance: i2, created_at: 1.month.ago }
        let!(:e5) { create :messages_to_bot_event, bot_instance: i2, created_at: 2.months.ago }
        let!(:e6) { create :messages_to_bot_event, bot_instance: i3, created_at: 2.months.ago }
        let!(:e7) { create :messages_to_bot_event, bot_instance: i3, created_at: 3.months.ago }
        let!(:e8) { create :messages_to_bot_event, bot_instance: i3, created_at: 4.months.ago }
        let!(:e9) { create :messages_to_bot_event, bot_instance: i3, created_at: 4.months.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'messages-to-bot', provider: 'slack')
        end

        it 'should return all messages' do
          dashboard.init!
          expect(dashboard.data.size).to eql 12
          expect(dashboard.data.values).to eql [0, 0, 0, 0, 0, 0, 0, 2, 1, 2, 1, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 2.0
        end
      end

      describe 'messages-from-bot' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: Time.now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 1.month.ago }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: 2.months.ago }
        let!(:i8) { create :bot_instance }

        let!(:e1) { create :messages_from_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e2) { create :messages_from_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e3) { create :messages_from_bot_event, bot_instance: i1, created_at: Time.now }
        let!(:e4) { create :messages_from_bot_event, bot_instance: i2, created_at: 1.month.ago }
        let!(:e5) { create :messages_from_bot_event, bot_instance: i2, created_at: 2.months.ago }
        let!(:e6) { create :messages_from_bot_event, bot_instance: i3, created_at: 2.months.ago }
        let!(:e7) { create :messages_from_bot_event, bot_instance: i3, created_at: 3.months.ago }
        let!(:e8) { create :messages_from_bot_event, bot_instance: i3, created_at: 4.months.ago }
        let!(:e9) { create :messages_from_bot_event, bot_instance: i3, created_at: 4.months.ago }

        before do
          dashboard.update_attributes(dashboard_type: 'messages-from-bot', provider: 'slack')
        end

        it 'should return all messages' do
          dashboard.init!
          expect(dashboard.data.size).to eql 12
          expect(dashboard.data.values).to eql [0, 0, 0, 0, 0, 0, 0, 2, 1, 2, 1, 3]
          expect(dashboard.count).to eql 3
          expect((dashboard.growth * 100).round / 100.0).to eql 2.0
        end
      end
    end
  end
end

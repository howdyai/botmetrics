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

    describe 'regex errors' do
      let!(:dashboard) { build :dashboard }

      it 'should now allow invalid regexs for regex' do
        dashboard.dashboard_type = 'custom'
        dashboard.regex = "(abc"

        expect(dashboard).to_not be_valid
        expect(dashboard.errors[:regex]).to eql ["end pattern with unmatched parenthesis: /(abc/"]
      end

      it 'should allow valid regexs for regex' do
        dashboard.dashboard_type = 'custom'
        dashboard.regex = "(abc)"

        expect(dashboard).to be_valid
      end
    end
  end

  describe 'associations' do
    it { should belong_to :bot }
    it { should belong_to :user }
    it { should have_many :dashboard_events }
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

        let!(:e1) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i1, created_at: i1.created_at }
        let!(:e2) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i2, created_at: i2.created_at }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-installed', provider: 'slack', event_type: 'bot-installed')
        end

        it 'should return all installed bots' do
          dashboard.init!
          expect(dashboard.data).to eql 2
        end
      end
    end

    describe 'group_by is "today"' do
      before do
        dashboard.group_by = 'today'
        Timecop.freeze(2016, 8, 22, 10, 0, 0)
        @now = Time.now
      end

      after do
        Timecop.return
      end

      describe 'bots-installed' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 1.hour }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now }
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 1.day }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 1.day - 1.hour }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 1.day - 2.hours }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 2.days }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 2.days - 2.hours }
        let!(:i9) { create :bot_instance }

        let!(:e1) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i1, created_at: i1.created_at }
        let!(:e2) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i2, created_at: i2.created_at }
        let!(:e3) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i3, created_at: i3.created_at }
        let!(:e4) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i4, created_at: i4.created_at }
        let!(:e5) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i5, created_at: i5.created_at }
        let!(:e6) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i6, created_at: i6.created_at }
        let!(:e7) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i7, created_at: i7.created_at }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-installed', provider: 'slack', event_type: 'bot-installed')
        end

        it 'should return all installed bots in the last week' do
          dashboard.init!
          expect(dashboard.data.size).to eql 7
          expect(dashboard.data.values).to eql [0, 0, 0, 0, 2, 3, 2]
          expect(dashboard.count).to eql 2
          expect((dashboard.growth * 100).round / 100.0).to eql -0.33
        end
      end
    end

    describe 'group_by is "this-week"' do
      before do
        dashboard.group_by = 'this-week'
        # This date is a Monday so makes sure that everything works accordingly
        Timecop.freeze(2016, 8, 22, 10, 0, 0)
        @now = Time.now
      end

      after do
        Timecop.return
      end

      describe 'bots-installed' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 1.hour }
        # i3-i5 is Sunday
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 1.day }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 1.day - 1.hour }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 1.day - 2.hours }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 2.weeks }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 2.weeks - 1.hour }
        let!(:i9) { create :bot_instance }

        let!(:e1) { create :rolledup_event, count: 1, dashboard: dashboard, bot_instance: i1, created_at: i1.created_at }
        let!(:e2) { create :rolledup_event, count: 1, dashboard: dashboard, bot_instance: i2, created_at: i2.created_at }
        let!(:e3) { create :rolledup_event, count: 1, dashboard: dashboard, bot_instance: i3, created_at: i3.created_at }
        let!(:e4) { create :rolledup_event, count: 1, dashboard: dashboard, bot_instance: i4, created_at: i4.created_at }
        let!(:e5) { create :rolledup_event, count: 1, dashboard: dashboard, bot_instance: i5, created_at: i5.created_at }
        let!(:e6) { create :rolledup_event, count: 1, dashboard: dashboard, bot_instance: i6, created_at: i6.created_at }
        let!(:e7) { create :rolledup_event, count: 1, dashboard: dashboard, bot_instance: i7, created_at: i7.created_at }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-installed', provider: 'slack', event_type: 'bot-installed')
        end

        it 'should return all installed bots in the last week' do
          dashboard.init!
          expect(dashboard.data.size).to eql 4
          expect(dashboard.data.values).to eql [0, 2, 3, 2]
          expect(dashboard.count).to eql 2
          expect((dashboard.growth * 100).round / 100.0).to eql -0.33
        end
      end
    end

    describe 'group_by is "this-month"' do
      before do
        dashboard.group_by = 'this-month'
        # This date is a Monday so makes sure that everything works accordingly
        Timecop.freeze(2016, 8, 22, 10, 0, 0)
        @now = Time.now
      end

      after do
        Timecop.return
      end

      describe 'bots-installed' do
        let!(:i1) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now }
        let!(:i2) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now }

        # i3-i5 is Sunday
        let!(:i3) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 1.month }
        let!(:i4) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 1.month }
        let!(:i5) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 1.month }
        let!(:i6) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 2.months }
        let!(:i7) { create :bot_instance, :with_attributes, uid: SecureRandom.hex(8), bot: bot, state: 'enabled', created_at: @now - 2.months }
        let!(:i9) { create :bot_instance }

        let!(:e1) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i1, created_at: i1.created_at }
        let!(:e2) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i2, created_at: i2.created_at }
        let!(:e3) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i3, created_at: i3.created_at }
        let!(:e4) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i4, created_at: i4.created_at }
        let!(:e5) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i5, created_at: i5.created_at }
        let!(:e6) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i6, created_at: i6.created_at }
        let!(:e7) { create :rolledup_event, dashboard: dashboard, count: 1, bot_instance: i7, created_at: i7.created_at }

        before do
          dashboard.update_attributes(dashboard_type: 'bots-installed', provider: 'slack', event_type: 'bot-installed')
        end

        it 'should return all installed bots in the last week' do
          dashboard.init!
          expect(dashboard.data.size).to eql 12
          expect(dashboard.data.values).to eql [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 2]
          expect(dashboard.count).to eql 2
          expect((dashboard.growth * 100).round / 100.0).to eql -0.33
        end
      end
    end
  end
end

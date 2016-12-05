require 'rails_helper'

RSpec.describe RolledupEventQueue, type: :model do
  let!(:bot)    { create :bot, provider: 'slack' }
  let!(:owner)  { create :user }
  let!(:bc1)    { create :bot_collaborator, bot: bot, user: owner       }
  let!(:bi)     { create :bot_instance, bot: bot, provider: 'slack'     }
  let!(:user)   { create :bot_user, bot_instance: bi, provider: 'slack' }

  before do
    bot.create_default_dashboards_with!(owner)
    @now = Time.now.utc.beginning_of_hour

    travel_to @now
  end

  after do
    travel_back
  end

  context 'without any existing rolled up events' do
    let!(:dashboard) { bot.dashboards.find_by(dashboard_type: 'bots-installed') }

    let!(:req1) { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now }
    let!(:req2) { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now }
    let!(:req3) { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now }

    let!(:req4) { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now + 1.hour  }
    let!(:req5) { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now + 2.hours }

    it 'should roll up events' do
      expect(RolledupEvent.count).to eql 0
      RolledupEventQueue.connection.execute("SELECT flush_rolledup_event_queue();")
      expect(RolledupEvent.count).to eql 3

      re1 = RolledupEvent.find_by(created_at: @now)
      re2 = RolledupEvent.find_by(created_at: @now + 1.hour)
      re3 = RolledupEvent.find_by(created_at: @now + 2.hours)

      expect(re1.count).to eql 3
      expect(re2.count).to eql 1
      expect(re3.count).to eql 1
    end

    it 'should delete all events in the RolledupEventQueue' do
      expect(RolledupEventQueue.count).to eql 5
      RolledupEventQueue.connection.execute("SELECT flush_rolledup_event_queue();")
      expect(RolledupEventQueue.count).to eql 0
    end
  end

  context 'with existing rolled up events' do
    let!(:dashboard) { bot.dashboards.find_by(dashboard_type: 'bots-installed') }

    let!(:re1)  { create :rolledup_event, bot_instance: bi, dashboard: dashboard, created_at: @now, count: 5, bot_instance_id_bot_user_id: "#{bi.id}:0" }

    let!(:req1)  { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now }
    let!(:req2)  { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now }
    let!(:req3)  { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now }

    let!(:req4) { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now + 1.hour  }
    let!(:req5) { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now + 2.hours }

    it 'should roll up events' do
      expect(RolledupEvent.count).to eql 1
      RolledupEventQueue.connection.execute("SELECT flush_rolledup_event_queue();")
      expect(RolledupEvent.count).to eql 3

      re1 = RolledupEvent.find_by(created_at: @now)
      re2 = RolledupEvent.find_by(created_at: @now + 1.hour)
      re3 = RolledupEvent.find_by(created_at: @now + 2.hours)

      expect(re1.count).to eql 8
      expect(re2.count).to eql 1
      expect(re3.count).to eql 1
    end

    it 'should delete all events in the RolledupEventQueue' do
      expect(RolledupEventQueue.count).to eql 5
      RolledupEventQueue.connection.execute("SELECT flush_rolledup_event_queue();")
      expect(RolledupEventQueue.count).to eql 0
    end
  end

  context 'with custom events and events associated with a user' do
    let!(:dashboard)          { bot.dashboards.find_by(dashboard_type: 'bots-installed') }
    let!(:messages_dashboard) { bot.dashboards.find_by(dashboard_type: 'messages') }

    let!(:re1)  { create :rolledup_event, bot_instance: bi, dashboard: dashboard, created_at: @now, count: 5, bot_instance_id_bot_user_id: "#{bi.id}:0" }
    let!(:re2)  { create :rolledup_event, bot_instance: bi, dashboard: messages_dashboard, bot_user: user, created_at: @now, count: 5, bot_instance_id_bot_user_id: "#{bi.id}:#{user.id}" }

    let!(:req1)  { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now }
    let!(:req2)  { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now }
    let!(:req3)  { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now }

    let!(:req4) { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now + 1.hour  }
    let!(:req5) { create :rolledup_event_queue, bot_instance: bi, dashboard: dashboard, created_at: @now + 2.hours }

    let!(:req7) { create :rolledup_event_queue, bot_instance: bi, bot_user: user, dashboard: messages_dashboard, created_at: @now }

    it 'should roll up events' do
      expect(RolledupEvent.count).to eql 2
      RolledupEventQueue.connection.execute("SELECT flush_rolledup_event_queue();")
      expect(RolledupEvent.count).to eql 4

      re1 = RolledupEvent.find_by(created_at: @now, dashboard: dashboard)
      re2 = RolledupEvent.find_by(created_at: @now + 1.hour)
      re3 = RolledupEvent.find_by(created_at: @now + 2.hours)
      re4 = RolledupEvent.find_by(created_at: @now, dashboard: messages_dashboard)

      expect(re1.count).to eql 8
      expect(re2.count).to eql 1
      expect(re3.count).to eql 1
      expect(re4.count).to eql 6
    end

    it 'should delete all events in the RolledupEventQueue' do
      expect(RolledupEventQueue.count).to eql 6
      RolledupEventQueue.connection.execute("SELECT flush_rolledup_event_queue();")
      expect(RolledupEventQueue.count).to eql 0
    end
  end
end

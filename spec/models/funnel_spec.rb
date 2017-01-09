require 'rails_helper'

RSpec.describe Funnel, type: :model do
  describe 'validations' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :bot_id }
    it { should validate_presence_of :user_id }
  end

  describe 'associations' do
    it { should belong_to :bot }
    it { should belong_to :creator }
  end

  describe '#events' do
    let!(:bot)          { create :bot, provider: 'facebook' }
    let!(:bot_instance) { create :bot_instance, bot: bot, provider: 'facebook' }
    let(:dashboard1)   { create :dashboard, provider: 'facebook', bot: bot, dashboard_type: 'new-users' }
    let(:dashboard2)   { create :dashboard, provider: 'facebook', bot: bot, dashboard_type: 'image-uploaded' }

    let(:funnel)       { create :funnel, bot: bot, dashboards: ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}"] }

    context 'with regular event types' do
      before do
        @now = Time.now
        travel_to @now

        @events = []
        @user_added_events = []

        dashboard1.set_event_type_and_query_options!
        dashboard1.save

        dashboard2.set_event_type_and_query_options!
        dashboard2.save

        @bu1 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now - 2.days
        @user_added_events << Event.order("id DESC").first
        @bu2 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now - 2.days
        @user_added_events << Event.order("id DESC").first
        @bu3 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now - 2.days
        @user_added_events << Event.order("id DESC").first
        @bu4 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now - 2.days
        @user_added_events << Event.order("id DESC").first

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, created_at: @now - 1.day)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, created_at: @now - 1.day)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, created_at: @now - 1.day)

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, created_at: @now - 25.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, created_at: @now - 25.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, created_at: @now - 25.hours)

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, created_at: @now - 27.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, created_at: @now - 27.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, created_at: @now - 27.hours)

        @events << create(:facebook_image_event, user: @bu1, bot_instance: bot_instance, created_at: @now)
        @events << create(:facebook_image_event, user: @bu2, bot_instance: bot_instance, created_at: @now)
        @events << create(:facebook_image_event, user: @bu3, bot_instance: bot_instance, created_at: @now)

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, created_at: @now + 1.day)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, created_at: @now + 1.day)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, created_at: @now + 1.day)

        @events << create(:facebook_image_event, user: @bu1, bot_instance: bot_instance, created_at: @now + 2.days)
        @events << create(:facebook_image_event, user: @bu2, bot_instance: bot_instance, created_at: @now + 2.days)
        @events << create(:facebook_image_event, user: @bu3, bot_instance: bot_instance, created_at: @now + 2.days)
      end

      it 'should return the events between the two steps (excluding the start and stop events)' do
        events = funnel.events(@bu1, step: 0, start_time: @now - 3.days, end_time: @now + 3.days)
        expect(events.to_a).to eql [@user_added_events[0], @events[0], @events[3], @events[6], @events[9]]

        events = funnel.events(@bu2, step: 0, start_time: @now - 3.days, end_time: @now + 3.days)
        expect(events.to_a).to eql [@user_added_events[1], @events[1], @events[4], @events[7], @events[10]]

        events = funnel.events(@bu3, step: 0, start_time: @now - 3.days, end_time: @now + 3.days)
        expect(events.to_a).to eql [@user_added_events[2], @events[2], @events[5], @events[8], @events[11]]
      end

      context 'with most_recent=true' do
        it 'should return the most recent event' do
          event = funnel.events(@bu1, step: 0, start_time: @now - 3.days, end_time: @now + 3.days, most_recent: true)
          expect(event).to eql @events[6]

          event = funnel.events(@bu2, step: 0, start_time: @now - 3.days, end_time: @now + 3.days, most_recent: true)
          expect(event).to eql @events[7]

          event = funnel.events(@bu3, step: 0, start_time: @now - 3.days, end_time: @now + 3.days, most_recent: true)
          expect(event).to eql @events[8]
        end
      end
    end

    context 'with custom dashboards' do
      let(:dashboard1)   { create :dashboard, provider: 'facebook', bot: bot, dashboard_type: 'custom', regex: 'abc' }
      let(:dashboard2)   { create :dashboard, provider: 'facebook', bot: bot, dashboard_type: 'custom', regex: 'def' }

      before do
        @now = Time.now
        travel_to @now

        @events, @user_added_events = [], []

        dashboard1.set_event_type_and_query_options!
        dashboard1.save

        dashboard2.set_event_type_and_query_options!
        dashboard2.save

        @bu1 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now - 2.days
        @bu2 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now - 2.days
        @bu3 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now - 2.days
        @bu4 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now - 2.days

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, created_at: @now - 2.days)
        create(:dashboard_event, dashboard: dashboard1, event: @events.last)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, created_at: @now - 2.days)
        create(:dashboard_event, dashboard: dashboard1, event: @events.last)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, created_at: @now - 2.days)
        create(:dashboard_event, dashboard: dashboard1, event: @events.last)

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, created_at: @now - 25.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, created_at: @now - 25.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, created_at: @now - 25.hours)

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, created_at: @now - 27.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, created_at: @now - 27.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, created_at: @now - 27.hours)

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, created_at: @now)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, created_at: @now)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, created_at: @now)

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, created_at: @now + 1.day)
        create(:dashboard_event, dashboard: dashboard2, event: @events.last)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, created_at: @now + 1.day)
        create(:dashboard_event, dashboard: dashboard2, event: @events.last)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, created_at: @now + 1.day)
        create(:dashboard_event, dashboard: dashboard2, event: @events.last)

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, created_at: @now + 1.day)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, created_at: @now + 1.day)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, created_at: @now + 1.day)
      end

      it 'should return the events between the two steps (excluding the start and stop events)' do
        events = funnel.events(@bu1, step: 0, start_time: @now - 3.days, end_time: @now + 3.days)
        expect(events.to_a).to eql [@events[0], @events[3], @events[6], @events[9], @events[12]]

        events = funnel.events(@bu2, step: 0, start_time: @now - 3.days, end_time: @now + 3.days)
        expect(events.to_a).to eql [@events[1], @events[4], @events[7], @events[10], @events[13]]

        events = funnel.events(@bu3, step: 0, start_time: @now - 3.days, end_time: @now + 3.days)
        expect(events.to_a).to eql [@events[2], @events[5], @events[8], @events[11], @events[14]]
      end

      context 'with most_recent=true' do
        it 'should return the most recent event' do
          event = funnel.events(@bu1, step: 0, start_time: @now - 3.days, end_time: @now + 3.days, most_recent: true)
          expect(event).to eql @events[9]

          event = funnel.events(@bu2, step: 0, start_time: @now - 3.days, end_time: @now + 3.days, most_recent: true)
          expect(event).to eql @events[10]

          event = funnel.events(@bu3, step: 0, start_time: @now - 3.days, end_time: @now + 3.days, most_recent: true)
          expect(event).to eql @events[11]
        end
      end
    end
  end

  describe '#insights' do
    let!(:bot)          { create :bot, provider: 'facebook' }
    let!(:bot_instance) { create :bot_instance, bot: bot, provider: 'facebook' }
    let!(:dashboard1)   { create :dashboard, bot: bot, provider: 'facebook', dashboard_type: 'new-users' }
    let!(:dashboard2)   { create :dashboard, bot: bot, provider: 'facebook', dashboard_type: 'messages-to-bot' }
    let!(:dashboard3)   { create :dashboard, bot: bot, provider: 'facebook', dashboard_type: 'image-uploaded' }

    let!(:funnel)       { create :funnel, bot: bot, dashboards: ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard3.uid}"] }

    context 'regular dashboards' do
      before do
        @now = Time.now
        travel_to @now

        dashboard1.set_event_type_and_query_options!
        dashboard1.save

        dashboard2.set_event_type_and_query_options!
        dashboard2.save

        dashboard3.set_event_type_and_query_options!
        dashboard3.save

        # This automatically creates 'user-added' events
        @bu1 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now
        @bu2 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now
        @bu3 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now
        @bu4 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now

        create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 20.minutes)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 21.minutes)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 22.minutes)

        # These three will be have 'is_for_bot' set to true in a later spec so they are captured in variables
        @e1 = create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: false, created_at: @now + 20.minutes)
        @e2 = create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: false, created_at: @now + 20.minutes)
        @e3 = create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: false, created_at: @now + 20.minutes)

        create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 22.minutes)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 23.minutes)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 24.minutes)

        create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 1.hour)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 2.hours)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 3.hours)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 4.hours)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 5.hours)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 6.hours)

        # These events should be ignored since they are not addressed to the bot
        create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 1.hour)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 2.hours)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 3.hours)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 4.hours)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 5.hours)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 6.hours)

        # By making these only 40 minutes apart, they get rolled up as part of the same hour as the
        # RolledupEvent for 'messages-to-bot' event, but insights should still be able to distinguish between the two
        create(:facebook_image_event, user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 6.hours)
        create(:facebook_image_event, user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 7.hours)
        create(:facebook_image_event, user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 8.hours)

        create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 1.day)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 1.day)
        create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 1.day)

        create(:facebook_image_event, user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 2.days)
        create(:facebook_image_event, user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 2.days)
        create(:facebook_image_event, user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 2.days)

        RolledupEventQueue.flush!
      end

      after do
        travel_back
      end

      context 'group_by_user' do
        it 'should return number of events grouped by user' do
          group_by_user = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_user]
          expect(group_by_user).to eql({@bu3.id => 5, @bu2.id => 4, @bu1.id => 3})
        end
      end

      context 'group_by_count' do
        it 'should return number of users grouped by number of steps' do
          result = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_count]
          expect(result).to eql([[5, 1], [4, 1], [3, 1]])
        end

        context 'if all users go through the same number of steps' do
          it 'should return number of users grouped by number of steps' do
            @e1.update_attribute(:is_for_bot, true)
            @e2.update_attribute(:is_for_bot, true)
            @e3.update_attribute(:is_for_bot, true)

            result = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_count]
            expect(result).to eql([[5, 3]])
          end
        end
      end

      context "between two steps that don't have any intermediate steps" do
        before do
          funnel.update_attributes(dashboards: ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}"])
        end

        it 'should return number of events grouped by user' do
          group_by_user = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_user]
          expect(group_by_user).to eql({@bu3.id => 0, @bu2.id => 0, @bu1.id => 0})
        end

        context 'aggregate_by_count is true' do
          it 'should return number of users grouped by number of steps' do
            result = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_count]
            expect(result).to eql([[0, 3]])
          end
        end
      end
    end

    context 'with custom dashboards' do
      before do
        dashboard3.update_attributes(dashboard_type: 'custom', regex: 'abc')

        @now = Time.now
        travel_to @now

        @events = []

        dashboard1.set_event_type_and_query_options!
        dashboard1.save

        dashboard2.set_event_type_and_query_options!
        dashboard2.save

        dashboard3.set_event_type_and_query_options!
        dashboard3.save

        # This automatically creates 'user-added' events
        @bu1 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now
        @bu2 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now
        @bu3 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now
        @bu4 = create :bot_user, provider: 'facebook', bot_instance: bot_instance, created_at: @now

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 20.minutes)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 21.minutes)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 22.minutes)

        # These three will be have 'is_for_bot' set to true in a later spec
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: false, created_at: @now + 20.minutes)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: false, created_at: @now + 20.minutes)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: false, created_at: @now + 20.minutes)

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 22.minutes)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 23.minutes)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 24.minutes)

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 1.hour)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 2.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 3.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 4.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 5.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 6.hours)

        @events << # These events should be ignored since they are not addressed to the bot
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 1.hour)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 2.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 3.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 4.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 5.hours)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: false, is_from_bot: true, created_at: @now + 6.hours)

        # By making these only 40 minutes apart, they get rolled up as part of the same hour as the
        # RolledupEvent for 'messages-to-bot' event, but insights should still be able to distinguish between the two
        @events << create(:messages_to_bot_event, user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 6.hours)
        create(:dashboard_event, dashboard: dashboard3, event: @events.last, created_at: @now)
        @events << create(:messages_to_bot_event, user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 7.hours)
        create(:dashboard_event, dashboard: dashboard3, event: @events.last, created_at: @now)
        @events << create(:messages_to_bot_event, user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 8.hours)
        create(:dashboard_event, dashboard: dashboard3, event: @events.last, created_at: @now)

        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 1.day)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 1.day)
        @events << create(:messages_to_bot_event, provider: 'facebook', user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 1.day)

        @events << create(:messages_to_bot_event, user: @bu1, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 2.days)
        create(:dashboard_event, dashboard: dashboard3, event: @events.last, created_at: @now + 2.days)
        @events << create(:messages_to_bot_event, user: @bu2, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 2.days)
        create(:dashboard_event, dashboard: dashboard3, event: @events.last, created_at: @now + 2.days)
        @events << create(:messages_to_bot_event, user: @bu3, bot_instance: bot_instance, is_for_bot: true, created_at: @now + 2.days)
        create(:dashboard_event, dashboard: dashboard3, event: @events.last, created_at: @now + 2.days)

        RolledupEventQueue.flush!
      end

      after do
        travel_back
      end

      context 'group_by_user' do
        it 'should return number of events grouped by user' do
          group_by_user = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_user]
          expect(group_by_user).to eql({@bu3.id => 5, @bu2.id => 4, @bu1.id => 3})
        end
      end

      context 'group_by_count' do
        it 'should return number of users grouped by number of steps' do
          result = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_count]
          expect(result).to eql([[5, 1], [4, 1], [3, 1]])
        end

        context 'if all users go through the same number of steps' do
          it 'should return number of users grouped by number of steps' do
            @events[3].update_attributes(is_for_bot: true)
            @events[4].update_attributes(is_for_bot: true)
            @events[5].update_attributes(is_for_bot: true)

            result = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_count]
            expect(result).to eql([[5, 3]])
          end
        end
      end

      context "between two steps that don't have any intermediate steps" do
        before do
          funnel.update_attributes(dashboards: ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}"])
        end

        context 'group_by_user' do
          it 'should return number of events grouped by user' do
            group_by_user = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_user]
            expect(group_by_user).to eql({@bu3.id => 0, @bu2.id => 0, @bu1.id => 0})
          end
        end

        context 'group_by_count' do
          it 'should return number of users grouped by number of steps' do
            result = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_count]
            expect(result).to eql([[0, 3]])
          end
        end
      end
    end
  end

  describe '#conversion' do
    let!(:bot)          { create :bot }
    let!(:bot_instance) { create :bot_instance, bot: bot }
    let!(:dashboard1)   { create :dashboard, bot: bot, dashboard_type: 'new-users' }
    let!(:dashboard2)   { create :dashboard, bot: bot, dashboard_type: 'messages-to-bot' }
    let!(:dashboard3)   { create :dashboard, bot: bot, dashboard_type: 'image-uploaded' }
    let!(:funnel)       { create :funnel, bot: bot, dashboards: ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}"] }

    context 'two step funnel' do
      before do
        @now = Time.now
        travel_to @now
        @bot_users = []
        20.times { @bot_users << create(:bot_user, bot_instance: bot_instance) }

        # These will be ignored since they are outside the default time period of 1.week.ago..Time.current
        20.times { |n| create :rolledup_event, count: 1, dashboard: dashboard1, bot_instance: bot_instance, bot_user: create(:bot_user), created_at: @now.beginning_of_hour - (n+1).weeks }
        10.times { |n| create :rolledup_event, count: 1, dashboard: dashboard2, bot_instance: bot_instance, bot_user: create(:bot_user), created_at: @now.beginning_of_hour + ((n+1)*2).weeks }

        20.times { |n| create :rolledup_event, count: 5, dashboard: dashboard1, bot_instance: bot_instance, bot_user: @bot_users[n], created_at: @now.beginning_of_hour - n.hours }
        11.times { |n| create :rolledup_event, count: 5, dashboard: dashboard2, bot_instance: bot_instance, bot_user: @bot_users[n], created_at: @now.beginning_of_hour + n.minutes }
        # These fall in the same time range but belong to other users
        11.times { |n| create :rolledup_event, count: 5, dashboard: dashboard2, bot_instance: bot_instance, bot_user: create(:bot_user), created_at: @now.beginning_of_hour + n.hours + 2.minutes}
      end

      after do
        travel_back
      end

      it 'should return the conversion numbers in a hash' do
        expect(funnel.conversion).to eql({"Signed Up" => 20, "Sent a Message to Bot for the First Time" => 11})
      end
    end

    context 'three step funnel' do
      before do
        funnel.update_attributes(dashboards: ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}", "dashboard:#{dashboard3.uid}"])

        @now = Time.now
        travel_to @now
        @bot_users = []
        20.times { @bot_users << create(:bot_user, bot_instance: bot_instance) }

        # These will be ignored since they are outside the default time period of 1.week.ago..Time.current
        20.times { |n| create :rolledup_event, count: 1, dashboard: dashboard1, bot_instance: bot_instance, bot_user: create(:bot_user), created_at: @now.beginning_of_hour - (n+1).weeks }
        10.times { |n| create :rolledup_event, count: 1, dashboard: dashboard2, bot_instance: bot_instance, bot_user: create(:bot_user), created_at: @now.beginning_of_hour + ((n+1)*2).weeks }

        20.times { |n| create :rolledup_event, count: 5, dashboard: dashboard1, bot_instance: bot_instance, bot_user: @bot_users[n], created_at: @now.beginning_of_hour - n.hours }
        11.times { |n| create :rolledup_event, count: 5, dashboard: dashboard2, bot_instance: bot_instance, bot_user: @bot_users[n], created_at: @now.beginning_of_hour + n.minutes }
        5.times { |n| create :rolledup_event, count: 5, dashboard: dashboard3, bot_instance: bot_instance, bot_user: @bot_users[n], created_at: @now.beginning_of_hour + n.minutes + 2.minutes }
        # These fall in the same time range but belong to other users
        11.times { |n| create :rolledup_event, count: 5, dashboard: dashboard2, bot_instance: bot_instance, bot_user: create(:bot_user), created_at: @now.beginning_of_hour + n.hours + 2.minutes}
      end

      after do
        travel_back
      end

      it 'should return the conversion numbers in a hash' do
        expect(funnel.conversion).to eql({"Signed Up" => 20, "Sent a Message to Bot for the First Time" => 11, "Uploaded an Image" => 5})
      end
    end
  end
end

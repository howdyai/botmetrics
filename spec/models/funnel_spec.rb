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

  describe '#insights' do
    let!(:bot)          { create :bot }
    let!(:bot_instance) { create :bot_instance, bot: bot }
    let!(:dashboard1)   { create :dashboard, bot: bot, dashboard_type: 'new-users' }
    let!(:dashboard2)   { create :dashboard, bot: bot, dashboard_type: 'messages-to-bot' }
    let!(:dashboard3)   { create :dashboard, bot: bot, dashboard_type: 'image-uploaded' }

    let!(:bu1)          { create :bot_user, bot_instance: bot_instance }
    let!(:bu2)          { create :bot_user, bot_instance: bot_instance }
    let!(:bu3)          { create :bot_user, bot_instance: bot_instance }
    let!(:bu4)          { create :bot_user, bot_instance: bot_instance }

    let!(:funnel)       { create :funnel, bot: bot, dashboards: ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard3.uid}"] }

    before do
      @now = Time.now
      travel_to @now
      # users all created at the same time
      create(:rolledup_event, bot_user: bu1, bot_instance: bot_instance, count: 1, dashboard: dashboard1, created_at: @now - 2.days)
      create(:rolledup_event, bot_user: bu2, bot_instance: bot_instance, count: 1, dashboard: dashboard1, created_at: @now - 2.days)
      create(:rolledup_event, bot_user: bu3, bot_instance: bot_instance, count: 1, dashboard: dashboard1, created_at: @now - 2.days)
      create(:rolledup_event, bot_user: bu4, bot_instance: bot_instance, count: 1, dashboard: dashboard1, created_at: @now - 2.days)

      create(:rolledup_event, bot_user: bu1, bot_instance: bot_instance, count: 1, dashboard: dashboard2, created_at: @now - 1.day)
      create(:rolledup_event, bot_user: bu2, bot_instance: bot_instance, count: 1, dashboard: dashboard2, created_at: @now - 1.day)
      create(:rolledup_event, bot_user: bu3, bot_instance: bot_instance, count: 1, dashboard: dashboard2, created_at: @now - 1.day)

      create(:rolledup_event, bot_user: bu1, bot_instance: bot_instance, count: 1, dashboard: dashboard2, created_at: @now - 25.hours)
      create(:rolledup_event, bot_user: bu2, bot_instance: bot_instance, count: 1, dashboard: dashboard2, created_at: @now - 25.hours)
      create(:rolledup_event, bot_user: bu3, bot_instance: bot_instance, count: 1, dashboard: dashboard2, created_at: @now - 25.hours)

      create(:rolledup_event, bot_user: bu1, bot_instance: bot_instance, count: 1, dashboard: dashboard2, created_at: @now - 27.hours)
      create(:rolledup_event, bot_user: bu2, bot_instance: bot_instance, count: 2, dashboard: dashboard2, created_at: @now - 27.hours)
      create(:rolledup_event, bot_user: bu3, bot_instance: bot_instance, count: 3, dashboard: dashboard2, created_at: @now - 27.hours)

      create(:rolledup_event, bot_user: bu1, bot_instance: bot_instance, count: 1, dashboard: dashboard3, created_at: @now)
      create(:rolledup_event, bot_user: bu2, bot_instance: bot_instance, count: 1, dashboard: dashboard3, created_at: @now)
      create(:rolledup_event, bot_user: bu3, bot_instance: bot_instance, count: 1, dashboard: dashboard3, created_at: @now)

      create(:rolledup_event, bot_user: bu1, bot_instance: bot_instance, count: 1, dashboard: dashboard2, created_at: @now + 1.day)
      create(:rolledup_event, bot_user: bu2, bot_instance: bot_instance, count: 1, dashboard: dashboard2, created_at: @now + 1.day)
      create(:rolledup_event, bot_user: bu3, bot_instance: bot_instance, count: 1, dashboard: dashboard2, created_at: @now + 1.day)

      create(:rolledup_event, bot_user: bu1, bot_instance: bot_instance, count: 1, dashboard: dashboard3, created_at: @now + 2.days)
      create(:rolledup_event, bot_user: bu2, bot_instance: bot_instance, count: 1, dashboard: dashboard3, created_at: @now + 2.days)
      create(:rolledup_event, bot_user: bu3, bot_instance: bot_instance, count: 1, dashboard: dashboard3, created_at: @now + 2.days)
    end

    after do
      travel_back
    end

    it 'should return number of events grouped by user' do
      group_by_user = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_user]
      expect(group_by_user).to eql({bu3.id => 5, bu2.id => 4, bu1.id => 3})
    end

    context 'aggregate_by_count is true' do
      it 'should return number of users grouped by number of steps' do
        result = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_count]
        expect(result).to eql([[5, 1], [4, 1], [3, 1]])
      end

      it 'should return number of users grouped by number of steps' do
        create(:rolledup_event, bot_user: bu1, bot_instance: bot_instance, count: 2, dashboard: dashboard2, created_at: @now - 28.hours)
        create(:rolledup_event, bot_user: bu2, bot_instance: bot_instance, count: 1, dashboard: dashboard2, created_at: @now - 28.hours)

        result = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_count]
        expect(result).to eql([[5, 3]])
      end
    end

    context "between two steps that don't have any intermediate steps" do
      before do
        funnel.update_attributes(dashboards: ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}"])
      end

      it 'should return number of events grouped by user' do
        group_by_user = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_user]
        expect(group_by_user).to eql({bu3.id => 0, bu2.id => 0, bu1.id => 0})
      end

      context 'aggregate_by_count is true' do
        it 'should return number of users grouped by number of steps' do
          result = funnel.insights(step: 0, start_time: @now - 3.days, end_time: @now + 3.days)[:group_by_count]
          expect(result).to eql([[0, 3]])
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
        11.times { |n| create :rolledup_event, count: 5, dashboard: dashboard2, bot_instance: bot_instance, bot_user: @bot_users[n], created_at: @now.beginning_of_hour + n.hours }
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
        11.times { |n| create :rolledup_event, count: 5, dashboard: dashboard2, bot_instance: bot_instance, bot_user: @bot_users[n], created_at: @now.beginning_of_hour + n.hours }
        5.times { |n| create :rolledup_event, count: 5, dashboard: dashboard3, bot_instance: bot_instance, bot_user: @bot_users[n], created_at: @now.beginning_of_hour + n.hours + 2.minutes }
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

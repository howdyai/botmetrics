require 'rails_helper'

RSpec.describe DashboardsController do
  def expect_track_mixpanel_event_job_to_have_received(message, user_id)
    expect(TrackMixpanelEventJob).to have_received(:perform_async).with(message, user_id)
  end

  describe 'GET new_bots' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot }
    let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }
    let!(:bi)   { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'enabled', bot: bot }

    def do_request
      get :new_bots, bot_id: bot.uid
    end

    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    it 'should render template :new_bots' do
      do_request
      expect(response).to render_template :new_bots
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect_track_mixpanel_event_job_to_have_received('Viewed New Bots Dashboard Page', user.id)
    end
  end

  describe '#disabled_bots' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot }
    let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }
    let!(:bi)   { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'disabled', bot: bot }

    def do_request
      get :disabled_bots, bot_id: bot.uid
    end

    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    it 'should render template :disabled_bots' do
      do_request
      expect(response).to render_template :disabled_bots
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect_track_mixpanel_event_job_to_have_received('Viewed Disabled Bots Dashboard Page', user.id)
    end
  end

  describe '#users' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot }
    let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }
    let!(:bi)   { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'disabled', bot: bot }

    def do_request
      get :users, bot_id: bot.uid
    end

    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    it 'should render template :users' do
      do_request
      expect(response).to render_template :users
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect_track_mixpanel_event_job_to_have_received('Viewed New Users Dashboard Page', user.id)
    end
  end

  describe '#all_messages' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot }
    let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }
    let!(:bi)   { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'disabled', bot: bot }

    def do_request
      get :all_messages, bot_id: bot.uid
    end

    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    it 'should render template :all_messages' do
      do_request
      expect(response).to render_template :all_messages
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect_track_mixpanel_event_job_to_have_received('Viewed All Messages Dashboard Page', user.id)
    end
  end

  describe '#messages_to_bot' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot }
    let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }
    let!(:bi)   { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'disabled', bot: bot }

    def do_request
      get :messages_to_bot, bot_id: bot.uid
    end

    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    it 'should render template :messages_to_bot' do
      do_request
      expect(response).to render_template :messages_to_bot
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect_track_mixpanel_event_job_to_have_received('Viewed Messages To Bot Dashboard Page', user.id)
    end
  end

  describe '#messages_from_bot' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot }
    let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }
    let!(:bi)   { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'disabled', bot: bot }

    def do_request
      get :messages_from_bot, bot_id: bot.uid
    end

    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    it 'should render template :messages_from_bot' do
      do_request
      expect(response).to render_template :messages_from_bot
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect_track_mixpanel_event_job_to_have_received('Viewed Messages From Bot Dashboard Page', user.id)
    end
  end
end

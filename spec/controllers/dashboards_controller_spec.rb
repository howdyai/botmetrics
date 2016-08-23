require 'rails_helper'

RSpec.describe DashboardsController do
  def expect_track_mixpanel_event_job_to_have_received(message, user_id)
    expect(TrackMixpanelEventJob).to have_received(:perform_async).with(message, user_id)
  end

  let!(:user) { create :user }
  let!(:bot)  { create :bot }
  let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }
  let!(:bi)   { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'enabled', bot: bot }

  describe 'POST create' do
    def do_request(params = {})
      post :create, bot_id: bot.uid, dashboard: params
    end

    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    it 'should create a new dashboard' do
      expect {
        do_request(name: 'My Custom Dashboard', regex: 'abc')
        bot.reload
      }.to change(bot.dashboards, :count).by(1)

      dashboard = bot.dashboards.last
      expect(dashboard.name).to eql 'My Custom Dashboard'
      expect(dashboard.regex).to eql 'abc'
      expect(dashboard.dashboard_type).to eql 'custom'
      expect(dashboard.enabled).to be true
      expect(dashboard.user).to eql user
    end

    it 'should redirect to bot_dashboards_path' do
      do_request(name: 'My Custom Dashboard', regex: 'abc')
      expect(response).to redirect_to bot_dashboards_path
    end
  end

  describe 'GET index' do
    def do_request
      get :index, bot_id: bot.uid
    end

    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    it 'should render template index' do
      do_request
      expect(response).to render_template :index
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect_track_mixpanel_event_job_to_have_received('Viewed Bot Dashboard Page', user.id)
    end
  end

  describe 'GET show' do
    let!(:dashboard) { create :dashboard, bot: bot }

    def do_request
      get :show, bot_id: bot.uid, id: dashboard.uid
    end

    before do
      sign_in user
      allow(TrackMixpanelEventJob).to receive(:perform_async)
    end

    it 'should render template show' do
      do_request
      expect(response).to render_template :show
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect_track_mixpanel_event_job_to_have_received("Viewed #{dashboard.name} Dashboard Page", user.id)
    end
  end
end

require 'rails_helper'

RSpec.describe PathsController, type: :controller do
  let!(:user) { create :user }
  let!(:bot)  { create :bot  }
  let!(:bi)   { create :bot_instance, bot: bot }
  let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }

  describe 'GET index' do
    before { sign_in user }

    def do_request
      get :index, bot_id: bot.uid
    end

    context 'without any created funnels' do
      it 'should redirect to new_bot_path_path' do
        do_request
        expect(response).to redirect_to new_bot_path_path
      end
    end

    context 'with a funnel' do
      let!(:funnel) { create :funnel, bot: bot, creator: user }

      it 'should render template :index' do
        do_request
        expect(response).to render_template :index
      end
    end
  end

  describe 'GET new' do
    before { sign_in user }

    def do_request
      get :new, bot_id: bot.uid
    end

    it 'should render template :new' do
      do_request
      expect(response).to render_template :new
    end
  end

  describe 'GET show' do
    before { sign_in user }
    let!(:funnel) { create :funnel, bot: bot, creator: user }

    def do_request
      get :show, bot_id: bot.uid, id: funnel.uid
    end

    it 'should render template :show' do
      do_request
      expect(response).to render_template :show
    end
  end

  describe 'GET edit' do
    before { sign_in user }
    let!(:funnel) { create :funnel, bot: bot, creator: user }

    def do_request
      get :edit, bot_id: bot.uid, id: funnel.uid
    end

    it 'should render template :edit' do
      do_request
      expect(response).to render_template :edit
    end
  end

  describe 'PATCH update' do
    before { sign_in user }

    let!(:funnel) { create :funnel, bot: bot, creator: user }

    def do_request(params = {})
      patch :update, bot_id: bot.uid, id: funnel.uid, funnel: params
    end

    context 'with valid params' do
      let!(:dashboard1) { create :dashboard, bot: bot }
      let!(:dashboard2) { create :dashboard, bot: bot }
      let!(:dashboard3) { create :dashboard, bot: bot }

      it 'should update the dashboard' do
        expect {
          do_request(dashboards: [dashboard1.uid, dashboard2.uid, dashboard3.uid])
          funnel.reload
        }.to change(funnel, :dashboards).to(["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}", "dashboard:#{dashboard3.uid}"])
      end

      it 'should redirect to the funnel page ' do
        do_request(dashboards: [dashboard1.uid, dashboard2.uid, dashboard3.uid])
        expect(response).to redirect_to bot_path_path(bot, funnel)
      end

      context 'with one of the dashboards is abandoned-chat' do
        let!(:dashboard1) { create :dashboard, bot: bot }
        let!(:dashboard2) { create :dashboard, bot: bot }
        let!(:dashboard3) { create :dashboard, bot: bot }

        it 'should create a new dashboard' do
          expect {
            do_request(dashboards: [dashboard1.uid, dashboard2.uid, dashboard3.uid, 'abandoned-chat'])
            funnel.reload
          }.to change(funnel, :dashboards).to(["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}", "dashboard:#{dashboard3.uid}", "dashboard:abandoned-chat"])
        end

        it 'should redirect to the funnel page' do
          do_request(dashboards: [dashboard1.uid, dashboard2.uid, dashboard3.uid, 'abandoned-chat'])
          funnel = bot.funnels.last
          expect(response).to redirect_to bot_path_path(bot, funnel)
        end
      end

      context 'with name' do
        it 'should update the dashboard' do
          expect {
            do_request(name: "New Name for Funnel", dashboards: [dashboard1.uid, dashboard2.uid, dashboard3.uid])
            funnel.reload
          }.to change(funnel, :dashboards).to(["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}", "dashboard:#{dashboard3.uid}"])
        end

        it 'should update the name of the funnel' do
          expect {
            do_request(name: "New Name for Funnel", dashboards: [dashboard1.uid, dashboard2.uid, dashboard3.uid])
            funnel.reload
          }.to change(funnel, :name).to("New Name for Funnel")
        end

        it 'should redirect to the funnel page ' do
          do_request(dashboards: [dashboard1.uid, dashboard2.uid, dashboard3.uid])
          expect(response).to redirect_to bot_path_path(bot, funnel)
        end
      end
    end

    context 'with invalid params' do
      context 'empty dashboards' do
        it 'should NOT update the funnel' do
          expect {
            do_request(dashboards: [])
            funnel.reload
          }.to_not change(funnel, :dashboards)
        end

        it 'should render template :edit' do
          do_request(dashboards: [])
          expect(response).to render_template :edit
        end
      end

      context 'less than 2 dashboards' do
        let!(:dash1) { create :dashboard, bot: bot }

        it 'should NOT update the funnel' do
          expect {
            do_request(dashboards: ["dashboard:#{dash1.uid}"])
            funnel.reload
          }.to_not change(funnel, :dashboards)
        end

        it 'should render template :edit' do
          do_request(dashboards: ["dashboard:#{dash1.uid}"])
          expect(response).to render_template :edit
        end
      end

      context 'with non-existent dashboards' do
        it 'should NOT update the funnel' do
          expect {
            do_request(dashboards: ["dashboard:non-existent1", "dashboard:non-existent2"])
            funnel.reload
          }.to_not change(funnel, :dashboards)
        end

        it 'should render template :edit' do
          do_request(dashboards: ["dashboard:non-existent1", "dashboard:non-existent2"])
          expect(response).to render_template :edit
        end
      end

      context 'with duplicate dashboards' do
        let!(:dash1) { create :dashboard, bot: bot }

        it 'should NOT update the funnel' do
          expect {
            do_request(dashboards: ["dashboard:#{dash1.uid}", "dashboard:#{dash1.uid}"])
            funnel.reload
          }.to_not change(funnel, :dashboards)
        end

        it 'should render template :edit' do
          do_request(dashboards: ["dashboard:#{dash1.uid}", "dashboard:#{dash1.uid}"])
          expect(response).to render_template :edit
        end
      end
    end
  end

  describe 'GET insights' do
    let!(:dashboard1) { create :dashboard, bot: bot }
    let!(:dashboard2) { create :dashboard, bot: bot }
    let!(:dashboard3) { create :dashboard, bot: bot }
    let!(:funnel)     { create :funnel, bot: bot, creator: user, dashboards: ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}", "dashboard:#{dashboard3.uid}"] }

    before { sign_in user }

    def do_request(params = {})
      get :insights, {bot_id: bot.uid, id: funnel.uid, format: 'json'}.merge(params)
    end

    context 'with valid params' do
      it 'should respond with 200' do
        do_request
        expect(response).to have_http_status :ok
      end
    end

    context 'with invalid params' do
      it 'should respond with 404' do
        do_request(step: 3)
        expect(response).to have_http_status :missing
      end

      context 'when step is last element' do
        it 'should respond with 404' do
          do_request(step: 2)
          expect(response).to have_http_status :missing
        end
      end
    end
  end

  describe 'GET events' do
    let!(:dashboard1) { create :dashboard, bot: bot, dashboard_type: 'new-users'       }
    let!(:dashboard2) { create :dashboard, bot: bot, dashboard_type: 'messages-to-bot' }
    let!(:dashboard3) { create :dashboard, bot: bot, dashboard_type: 'image-uploaded'  }

    let!(:funnel)     { create :funnel, bot: bot, creator: user, dashboards: ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}", "dashboard:#{dashboard3.uid}"] }
    let!(:bot_user)   { create :bot_user, bot_instance: bi }

    before do
      dashboard1.set_event_type_and_query_options!
      dashboard1.save

      dashboard2.set_event_type_and_query_options!
      dashboard2.save

      dashboard3.set_event_type_and_query_options!
      dashboard3.save

      sign_in user
    end

    def do_request(params = {})
      get :events, {bot_id: bot.uid, id: funnel.uid, format: 'json'}.merge(params)
    end

    context 'with valid params' do
      it 'should respond with 200' do
        do_request(bot_user_id: bot_user.id)
        expect(response).to have_http_status :ok
      end
    end

    context 'with invalid params' do
      it 'should respond with 404' do
        do_request(step: 3)
        expect(response).to have_http_status :missing
      end

      context 'when step is last element' do
        it 'should respond with 404' do
          do_request(step: 2)
          expect(response).to have_http_status :missing
        end
      end

      context 'with non-existent user-id' do
        it 'should respond with 404' do
          do_request(step: 0, bot_user_id: 'non-existent')
          expect(response).to have_http_status :missing
        end
      end
    end
  end

  describe 'POST create' do
    before { sign_in user }

    def do_request(params = {})
      post :create, bot_id: bot.uid, funnel: params
    end

    context 'with valid params' do
      let!(:dashboard1) { create :dashboard, bot: bot }
      let!(:dashboard2) { create :dashboard, bot: bot }
      let!(:dashboard3) { create :dashboard, bot: bot }

      it 'should create a new dashboard' do
        expect {
          do_request(name: 'My First Funnel', dashboards: [dashboard1.uid, dashboard2.uid, dashboard3.uid])
          bot.reload
        }.to change(bot.funnels, :count).by(1)

        funnel = bot.funnels.last
        expect(funnel.name).to eql 'My First Funnel'
        expect(funnel.dashboards).to eql ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}", "dashboard:#{dashboard3.uid}"]
        expect(funnel.creator).to eql user
      end

      it 'should redirect to the funnel name' do
        do_request(name: 'My First Funnel', dashboards: [dashboard1.uid, dashboard2.uid, dashboard3.uid])
        funnel = bot.funnels.last
        expect(response).to redirect_to bot_path_path(bot, funnel)
      end

      context 'with one of the dashboards is abandoned-chat' do
        let!(:dashboard1) { create :dashboard, bot: bot }
        let!(:dashboard2) { create :dashboard, bot: bot }
        let!(:dashboard3) { create :dashboard, bot: bot }

        it 'should create a new dashboard' do
          expect {
            do_request(name: 'My First Funnel', dashboards: [dashboard1.uid, dashboard2.uid, dashboard3.uid, 'abandoned-chat'])
            bot.reload
          }.to change(bot.funnels, :count).by(1)

          funnel = bot.funnels.last
          expect(funnel.name).to eql 'My First Funnel'
          expect(funnel.dashboards).to eql ["dashboard:#{dashboard1.uid}", "dashboard:#{dashboard2.uid}", "dashboard:#{dashboard3.uid}", "dashboard:abandoned-chat"]
          expect(funnel.creator).to eql user
        end

        it 'should redirect to the funnel name' do
          do_request(name: 'My First Funnel', dashboards: [dashboard1.uid, dashboard2.uid, dashboard3.uid, 'abandoned-chat'])
          funnel = bot.funnels.last
          expect(response).to redirect_to bot_path_path(bot, funnel)
        end
      end
    end

    context 'with invalid params' do
      context 'empty dashboards' do
        it 'should NOT create a new dashboard' do
          expect {
            do_request(name: 'My First Funnel', dashboards: [])
            bot.reload
          }.to_not change(bot.funnels, :count)
        end

        it 'should render template :new' do
          do_request(name: 'My First Funnel', dashboards: [])
          expect(response).to render_template :new
        end
      end

      context 'less than 2 dashboards' do
        let!(:dash1) { create :dashboard, bot: bot }

        it 'should NOT create a new dashboard' do
          expect {
            do_request(name: 'My First Funnel', dashboards: ["dashboard:#{dash1.uid}"])
            bot.reload
          }.to_not change(bot.funnels, :count)
        end

        it 'should render template :new' do
          do_request(name: 'My First Funnel', dashboards: [])
          expect(response).to render_template :new
        end
      end

      context 'with non-existent dashboards' do
        it 'should NOT create a new dashboard' do
          expect {
            do_request(name: 'My First Funnel', dashboards: ["dashboard:non-existent1", "dashboard:non-existent2"])
            bot.reload
          }.to_not change(bot.funnels, :count)
        end

        it 'should render template :new' do
          do_request(name: 'My First Funnel', dashboards: [])
          expect(response).to render_template :new
        end
      end

      context 'with duplicate dashboards' do
        let!(:dash1) { create :dashboard, bot: bot }

        it 'should NOT create a new dashboard' do
          expect {
            do_request(name: 'My First Funnel', dashboards: ["dashboard:#{dash1.uid}", "dashboard:#{dash1.uid}"])
            bot.reload
          }.to_not change(bot.funnels, :count)
        end

        it 'should render template :new' do
          do_request(name: 'My First Funnel', dashboards: [])
          expect(response).to render_template :new
        end
      end
    end
  end
end

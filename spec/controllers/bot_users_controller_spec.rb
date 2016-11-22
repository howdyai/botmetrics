require 'rails_helper'

RSpec.describe BotUsersController, type: :controller do
  describe 'PATCH update' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot }

    let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }

    let!(:bi1) { create :bot_instance, bot: bot }
    let!(:bi2) { create :bot_instance, bot: bot }
    let!(:bu1) { create :bot_user, bot_instance: bi1 }
    let!(:bu2) { create :bot_user, bot_instance: bi2 }
    let!(:bu3) { create :bot_user, bot_instance: bi2 }
    let!(:bu4) { create :bot_user }

    before { sign_in user }

    def do_request(user, timezone)
      patch :update, bot_id: bot.uid, id: user.uid, format: :json, user: { timezone: timezone }
    end

    context 'missing bot user' do
      it "should NOT update the user's timezone" do
        expect {
          do_request(bu4, 'GMT1')
          bu4.reload
        }.to_not change(bu4, :timezone)
      end

      it "should respond with :accepted" do
        do_request(bu4, 'GMT1')
        expect(response).to have_http_status :missing
      end
    end

    context 'valid timezone' do
      it "should update the user's timezone" do
        expect {
          do_request(bu1, 'GMT')
          bu1.reload
        }.to change(bu1, :timezone).to 'GMT'

        expect {
          do_request(bu2, 'GMT')
          bu2.reload
        }.to change(bu2, :timezone).to 'GMT'

        expect {
          do_request(bu3, 'GMT')
          bu3.reload
        }.to change(bu3, :timezone).to 'GMT'
      end

      it 'should respond with :accepted' do
        do_request(bu1, 'GMT')
        expect(response).to have_http_status :accepted
      end
    end

    context 'invalid timezone' do
      it "should NOT update the user's timezone" do
        expect {
          do_request(bu1, 'GMT1')
          bu1.reload
        }.to_not change(bu1, :timezone)
      end

      it "should respond with :accepted" do
        do_request(bu1, 'GMT1')
        expect(response).to have_http_status :bad_request
      end
    end
  end
end

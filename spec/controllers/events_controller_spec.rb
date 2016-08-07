require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  describe 'POST create' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot, provider: 'facebook'  }
    let!(:bc)   { create :bot_collaborator, bot: bot, user: user }
    let!(:bi)   { create :bot_instance, bot: bot }

    let(:event_json) do
      {
        "entry": [{
          "id": "268855423495782", "time": 1470403317713, "messaging": [{
            "sender":{
              "id":"USER_ID"
            },
            "recipient":{
              "id":"PAGE_ID"
            },
            "timestamp":1458692752478,
            "message":{
              "mid":"mid.1457764197618:41d102a3e1ae206a38",
              "seq":73,
              "text":"hello, world!",
              "quick_reply": {
                "payload": "DEVELOPER_DEFINED_PAYLOAD"
              }
            }
          }]
        }]
      }.to_json
    end

    def do_request(params = {})
      post :create, bot_id: bot.uid, event: event_json
    end

    before do
      allow(FacebookEventsCollectorJob).to receive(:perform_async).with(bot.uid, event_json)
      sign_in user
    end

    it 'should respond with 202 accepted' do
      do_request
      expect(response).to have_http_status(:accepted)
    end

    it 'should call FacebookEventsCollectorJob' do
      do_request
      expect(FacebookEventsCollectorJob).to have_received(:perform_async).with(bot.uid, event_json)
    end
  end
end

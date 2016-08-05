require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  describe 'POST create' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot  }
    let!(:bc)   { create :bot_collaborator, bot: bot, user: user }
    let!(:bi)   { create :bot_instance, bot: bot }
    let(:raw_data) {
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
      }
    }

    def do_request(params = {})
      post :create, bot_id: bot.uid, event: raw_data
    end

    before do
      allow_any_instance_of(Facebook).to receive(:call).and_return({ first_name: 'Vlad' })
      sign_in user
    end

    it 'should respond with 202 accepted' do
      do_request
      expect(response).to have_http_status(:accepted)
    end
  end
end

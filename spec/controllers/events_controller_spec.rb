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

    context "valid event JSON" do
      it 'should respond with 202 accepted' do
        do_request
        expect(response).to have_http_status(:accepted)
      end

      it 'should call FacebookEventsCollectorJob' do
        do_request
        expect(FacebookEventsCollectorJob).to have_received(:perform_async).with(bot.uid, event_json)
      end
    end

    context "invalid JSON" do
      let(:event_json) { "abc def" }

      it 'should respond with 400 bad request' do
        do_request
        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body['error']).to eql "Event parameter is not valid JSON"
      end

      it "should not call FacebookEventsCollectorJob" do
        do_request
        expect(FacebookEventsCollectorJob).to_not have_received(:perform_async)
      end
    end

    context "valid JSON but not valid Facebook data" do
      let(:event_json) { { data: 'test', abc: 'def' }.to_json }

      it 'should respond with 400 bad request' do
        do_request
        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body['error']).to eql "Invalid Facebook Event Data"
      end

      it "should not call FacebookEventsCollectorJob" do
        do_request
        expect(FacebookEventsCollectorJob).to_not have_received(:perform_async)
      end
    end
  end
end

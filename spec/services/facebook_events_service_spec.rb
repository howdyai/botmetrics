RSpec.describe FacebookEventsService do
  describe '.new' do
    context 'incorrect params' do
      let(:incorrect_options) { { bot_id: nil, raw_data: 'raw_data' } }

      it { expect { FacebookEventsService.new(incorrect_options) }.to raise_error("NoOptionSupplied: bot_id") }
    end
  end

  describe '#create_event' do
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
    let(:serialized) {
      [{
        data:  {
          event_type: "message",
          is_for_bot: true,
          is_im: true,
          is_from_bot: false,
          text: "hello, world!",
          provider: "facebook",
          event_attributes: {
            delivered: false,
            read: false,
            mid: "mid.1457764197618:41d102a3e1ae206a38",
            seq: 73,
            quick_reply: "DEVELOPER_DEFINED_PAYLOAD"}},
        recip_info: {
          sender_id: bot.uid, recipient_id: bot.uid
        }
      }]
    }
    let!(:bot) { create(:bot, :with_uid) }
    let!(:bot_instance) { create(:bot_instance, bot: bot) }

    before(:each) do
      allow_any_instance_of(Facebook).to receive(:call).and_return({ first_name: 'Vlad' })
    end

    context 'create with raw data' do
      subject { FacebookEventsService.new(bot_id: bot.uid, raw_data: raw_data).create_event }

      it { expect(subject.count).to eql 1 }
    end

    context 'new bot user' do
      subject { FacebookEventsService.new(bot_id: bot.uid, raw_data: raw_data).create_event }

      it { expect { subject }.to change { BotUser.count }.by 1 }
    end

    context 'existing bot user' do
      subject { FacebookEventsService.new(bot_id: bot.uid, raw_data: raw_data).create_event }

      let!(:bot_user) { create(:bot_user, :with_attributes) }

      it { expect { subject }.to change { BotUser.count }.by 0 }
    end
  end
end

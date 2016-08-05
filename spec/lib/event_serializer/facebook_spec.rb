RSpec.describe EventSerializer::Facebook do
  describe '.new' do
    context 'invalid params' do
      it { expect { EventSerializer::Facebook.new(nil) }.to raise_error('SuppliedOptionIsNil') }
    end
  end

  describe '#serialize' do
    subject { EventSerializer.new(:facebook, data).serialize }

    let(:data) {
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
            "#{event_type}":{
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
          event_type: 'message',
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
          sender_id: "USER_ID", recipient_id: "PAGE_ID"
        }
      }]
    }

    context 'incorrect event type' do
      let(:event_type) { 'incorrect' }

      it { expect { EventSerializer::Facebook.new(data).serialize }.to raise_error('IncorrectEventType') }
    end

    context 'correct event type' do
      let(:event_type) { 'message' }

      it { expect(subject).to eql serialized }
    end
  end
end

RSpec.describe EventSerializer::Facebook::Message do
  TIMESTAMP ||= 1458692752478

  describe '.new' do
    context 'invalid params' do
      it { expect { EventSerializer::Facebook.new(nil) }.to raise_error('SuppliedOptionIsNil') }
    end
  end

  describe '#serialize' do
    subject { EventSerializer::Facebook::Message.new(data).serialize }

    let(:data) {
      {
        "sender":{
          "id":"USER_ID"
        },
        "recipient":{
          "id":"PAGE_ID"
        },
        "timestamp":TIMESTAMP,
        "message":{
          "mid":"mid.1457764197618:41d102a3e1ae206a38",
          "seq":73,
          "text":"hello, world!",
          "quick_reply": {
            "payload": "DEVELOPER_DEFINED_PAYLOAD"
          }
        }
      }
    }
    let(:serialized) {
      {
        data:  {
          event_type: "message",
          is_for_bot: true,
          is_im: true,
          is_from_bot: false,
          text: "hello, world!",
          provider: "facebook",
          created_at: Time.at(TIMESTAMP.to_f / 1000),
          event_attributes: {
            delivered: false,
            read: false,
            mid: "mid.1457764197618:41d102a3e1ae206a38",
            seq: 73,
            quick_reply: "DEVELOPER_DEFINED_PAYLOAD"}},
        recip_info: {
          sender_id: "USER_ID", recipient_id: "PAGE_ID"
        }
      }
    }

    it { expect(subject).to eql serialized }
  end
end

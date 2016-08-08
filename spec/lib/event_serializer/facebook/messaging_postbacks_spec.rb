RSpec.describe EventSerializer::Facebook::MessagingPostbacks do
  TIMESTAMP ||= 1458692752478

  describe '.new' do
    context 'invalid params' do
      it { expect { EventSerializer::Facebook.new(nil) }.to raise_error('Supplied Option Is Nil') }
    end
  end

  describe '#serialize' do
    subject { EventSerializer::Facebook::MessagingPostbacks.new(data).serialize }

    let(:data) {
      {
        "sender":{
          "id":"USER_ID"
        },
        "recipient":{
          "id":"PAGE_ID"
        },
        "timestamp":TIMESTAMP,
        "postback":{
          "payload":"USER_DEFINED_PAYLOAD"
        }
      }
    }
    let(:serialized) {
      {
        data:  {
          event_type: "messaging_postbacks",
          is_for_bot: true,
          is_im: true,
          is_from_bot: false,
          provider: "facebook",
          created_at: Time.at(TIMESTAMP.to_f / 1000),
          event_attributes: {
            payload: "USER_DEFINED_PAYLOAD"
          }},
        recip_info: {
          sender_id: "USER_ID", recipient_id: "PAGE_ID"
        }
      }
    }

    it { expect(subject).to eql serialized }
  end
end

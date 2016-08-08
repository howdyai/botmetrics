RSpec.describe EventSerializer::Facebook::MessageEchoes do
  let(:timestamp) { Time.now.to_i * 1000 }

  describe '.new' do
    context 'invalid params' do
      it { expect { EventSerializer::Facebook.new(nil) }.to raise_error('Supplied Option Is Nil') }
    end
  end

  describe '#serialize' do
    subject { EventSerializer::Facebook::MessageEchoes.new(data).serialize }

    let(:data) {
      {
        "sender":{
          "id":"USER_ID"
        },
        "recipient":{
          "id":"PAGE_ID"
        },
        "timestamp":timestamp,
        "message":{
          "is_echo":true,
          "mid":"mid.1457764197618:41d102a3e1ae206a38",
          "seq":73,
          "text":"hello, world!"
        }
      }
    }
    let(:serialized) {
      {
        data:  {
          event_type: "message",
          is_for_bot: false,
          is_im: true,
          is_from_bot: true,
          text: "hello, world!",
          provider: "facebook",
          created_at: Time.at(timestamp.to_f / 1000),
          event_attributes: {
            mid: "mid.1457764197618:41d102a3e1ae206a38",
            seq: 73
          }
        },
        recip_info: {
          sender_id: "USER_ID", recipient_id: "PAGE_ID"
        }
      }
    }

    it { expect(subject).to eql serialized }
  end
end

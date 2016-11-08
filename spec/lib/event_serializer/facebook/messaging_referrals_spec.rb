RSpec.describe EventSerializer::Facebook::MessagingReferrals do
  let!(:timestamp)    { Time.now.to_i * 1000 }

  describe '.new' do
    context 'invalid params' do
      it { expect { EventSerializer::Facebook.new(nil, 'bi_uid') }.to raise_error('Supplied Option Is Nil') }
    end
  end

  describe '#serialize' do
    subject { EventSerializer::Facebook::MessagingReferrals.new(data).serialize }

    let(:data) {
      {
        "sender":{
          "id":"USER_ID"
        },
        "recipient":{
          "id":"PAGE_ID"
        },
        "timestamp":timestamp,
        "referral":{
          "ref":"producthunt",
          "source": "SHORTLINK",
          "type": "OPEN_THREAD"
        }
      }
    }
    let(:serialized) {
      {
        data:  {
          event_type: "messaging_referrals",
          is_for_bot: false,
          is_im: false,
          is_from_bot: false,
          provider: "facebook",
          created_at: Time.at(timestamp.to_f / 1000),
          event_attributes: {
            referral: {
              ref: "producthunt",
              source: "SHORTLINK",
              type: "OPEN_THREAD"
            }
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


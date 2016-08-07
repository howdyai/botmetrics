RSpec.describe EventSerializer::Facebook::MessageReads do
  TIMESTAMP ||= 1458692752478
  WATERMARK ||= 1458792752478

  describe '.new' do
    context 'invalid params' do
      it { expect { EventSerializer::Facebook.new(nil) }.to raise_error('SuppliedOptionIsNil') }
    end
  end

  describe '#serialize' do
    subject { EventSerializer::Facebook::MessageReads.new(data).serialize }

    let(:data) {
      {
        "sender":{
          "id":"USER_ID"
        },
        "recipient":{
          "id":"PAGE_ID"
        },
        "timestamp":TIMESTAMP,
        "read":{
           "watermark":WATERMARK,
           "seq":38
        }
      }
    }
    let(:serialized) {
      {
        data:  {
          event_type: "message_reads",
          watermark: Time.at(WATERMARK.to_f / 1000)
        },
        recip_info: {
          sender_id: "USER_ID", recipient_id: "PAGE_ID"
        }
      }
    }

    it { expect(subject).to eql serialized }
  end
end

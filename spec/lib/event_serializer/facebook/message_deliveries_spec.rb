RSpec.describe EventSerializer::Facebook::MessageDeliveries do
  let!(:timestamp)    { Time.now.to_i * 1000 }
  let!(:watermark)    { 1.day.since.to_i * 1000 }


  describe '.new' do
    context 'invalid params' do
      it { expect { EventSerializer::Facebook.new(nil) }.to raise_error('Supplied Option Is Nil') }
    end
  end

  describe '#serialize' do
    subject { EventSerializer::Facebook::MessageDeliveries.new(data).serialize }

    let(:data) {
      {
        "sender":{
          "id":"USER_ID"
        },
        "recipient":{
          "id":"PAGE_ID"
        },
        "delivery":{
          "mids":[
             "mid.1458668856218:ed81099e15d3f4f233"
          ],
          "watermark":watermark,
          "seq":37
        }
      }
    }
    let(:serialized) {
      {
        data:  {
          event_type: "message_deliveries",
          watermark: Time.at(watermark.to_f / 1000)
        },
        recip_info: {
          sender_id: "USER_ID", recipient_id: "PAGE_ID"
        }
      }
    }

    it { expect(subject).to eql serialized }
  end
end

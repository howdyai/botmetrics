RSpec.describe EventSerializer do
  let!(:timestamp)    { Time.now.to_i * 1000 }

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
          "timestamp":timestamp,
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
      data: {
        event_type: "message",
        is_for_bot: true,
        is_im: true,
        is_from_bot: false,
        text: "hello, world!",
        provider: "facebook",
        created_at: Time.at(timestamp.to_f / 1000),
        event_attributes: {
          mid: "mid.1457764197618:41d102a3e1ae206a38",
          seq: 73,
          quick_reply: "DEVELOPER_DEFINED_PAYLOAD"
        }
      },
      recip_info: {
        sender_id: "USER_ID", recipient_id: "PAGE_ID"
      }
    }]
  }

  describe '.new' do
    context 'invalid params' do
      it { expect { EventSerializer.new(nil, 'data', 'bi_uid') }.to raise_error('NoOptionSupplied') }
      it { expect { EventSerializer.new(:facebook, nil, 'bi_uid') }.to raise_error('NoOptionSupplied') }
    end

    context 'undefined constant' do
      it { expect { EventSerializer.new(:undefined, 'data', 'bi_uid') }.to raise_error(NameError) }
    end

    context 'defined constant' do
      it { expect(EventSerializer.new(:facebook, data, 'bi_uid')).to be_a(EventSerializer) }
    end
  end

  describe '#serialize' do
    subject { EventSerializer.new(:facebook, data, 'bi_uid').serialize }

    it { expect(subject).to eql serialized }
  end
end

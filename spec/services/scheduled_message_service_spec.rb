RSpec.describe ScheduledMessageService do
  describe '#perform' do
    let(:scheduled_at) { Time.zone.parse('2016-06-06 08:00 +0800') }
    let(:next_day) { Time.zone.parse('2016-06-07 08:00 +0800') }

    def perform
      described_class.new.send_now
    end

    before do
      create(:message, :to_user, sent_at: Time.current,  scheduled_at: scheduled_at)
      create(:message, :to_user, sent_at: nil, scheduled_at: scheduled_at)
      create(:message, :to_user, sent_at: nil, scheduled_at: next_day)
    end


    context 'wrong timing' do
      before { travel_to Time.zone.parse('2016-06-06 08:05 +1200') }

      it 'does not send anything' do
        allow(SendMessageJob).to receive(:perform_async)

        perform

        expect(SendMessageJob).to have_received(:perform_async).exactly(0).times
      end

      after { travel_back }
    end

    context 'exact timing' do
      before { travel_to Time.parse('2016-06-06 08:05 +0800') }

      it 'sends for scheduled message only' do
        allow(SendMessageJob).to receive(:perform_async)

        perform

        expect(SendMessageJob).to have_received(:perform_async).once
      end

      after { travel_back }
    end
  end
end

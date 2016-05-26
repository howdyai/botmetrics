RSpec.describe ScheduledMessageService do
  describe '#perform' do
    let!(:scheduled_messages) do
      create_list(:message, 2, :to_user, sent_at: nil, scheduled_at: scheduled_at)
    end

    let(:scheduled_at) { Time.parse('2016-05-15 08:00 +0200') }

    before do
      create(:message, :to_user, sent_at: Time.current,  scheduled_at: nil)
      create(:message, :to_user, sent_at: nil, scheduled_at: nil)
      create(:message, :to_user, sent_at: Time.current,  scheduled_at: scheduled_at)
      create(:message, :to_user, sent_at: nil, scheduled_at: Time.parse('2016-05-15 08:00 +0800'))
    end

    context 'wrong timing' do
      before { travel_to Time.parse('2016-05-15 08:05 +0400') }

      it 'does not send anything' do
        allow(SendMessageJob).to receive(:perform_async)

        ScheduledMessageService.new.send_now

        expect(SendMessageJob).to have_received(:perform_async).exactly(0).times
        scheduled_messages.each do |message|
          expect(SendMessageJob).to_not have_received(:perform_async).with(message.id)
        end
      end
    end

    context 'exact timing' do
      before { travel_to Time.parse('2016-05-15 08:05 +0200') }

      it 'sends for scheduled message only' do
        allow(SendMessageJob).to receive(:perform_async)

        ScheduledMessageService.new.send_now

        expect(SendMessageJob).to have_received(:perform_async).twice
        scheduled_messages.each do |message|
          expect(SendMessageJob).to have_received(:perform_async).with(message.id)
        end
      end
    end
  end
end

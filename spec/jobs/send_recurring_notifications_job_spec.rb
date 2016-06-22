RSpec.describe SendRecurringNotificationsJob do
  describe '#perform' do
    let!(:ns) { double(NotificationService) }
    let!(:n1) { create :notification }
    let!(:n2) { create :notification, recurring: true }
    let!(:n3) { create :notification, recurring: true }

    before do
      allow(NotificationService).to receive(:new).and_return(ns)
      allow(ns).to receive(:enqueue_messages)
    end

    it 'should enqueue messages for all recurring notifications' do
      SendRecurringNotificationsJob.new.perform
      expect(NotificationService).to have_received(:new).ordered.with(n2)
      expect(NotificationService).to have_received(:new).ordered.with(n3)
      expect(ns).to have_received(:enqueue_messages).twice
    end
  end
end

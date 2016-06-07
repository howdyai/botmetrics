require 'rails_helper'

RSpec.describe Notification do
  context 'associations' do
    it { is_expected.to belong_to :bot }

    it { is_expected.to have_one :query_set }
    it { is_expected.to have_many :messages }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of :content }

    context 'on: schedule' do
      describe '#verify_scheduled_at' do
        let(:notification) do
          build(:notification, scheduled_at: 'May 10, 2016 4:00 PM')
        end

        it 'is true when scheduled_at in Pacific/Apia (UTC+13/+14) >= current time' do
          travel_to Time.parse('May 10, 2016 3:59 PM +1300') do
            expect(notification.valid?(:schedule)).to be_truthy
          end
        end

        it 'is false when scheduled_at in Pacific/Apia (UTC+13/+14) < current time' do
          travel_to Time.parse('May 10, 2016 4:01 PM +1300') do
            expect(notification.valid?(:schedule)).to be_falsy
          end

          expect(notification.errors[:scheduled_at]).to be_present
        end
      end
    end
  end

  describe '#send_immediately?' do
    it 'is false when send_at is blank' do
      notification = Notification.new(scheduled_at: nil)
      expect(notification.send_immediately?).to be_truthy
    end

    it 'is true when scheduled_at is present' do
      notification = Notification.new(scheduled_at: 'May 15, 2016 8:00 PM')
      expect(notification.send_immediately?).to be_falsy
    end
  end
end

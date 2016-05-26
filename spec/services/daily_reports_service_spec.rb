RSpec.describe DailyReportsService do
  describe '#send_now' do
    let(:service) { DailyReportsService.new }

    before { allow(ReportsMailer).to receive(:daily_summary) { double(:mail).as_null_object } }

    it 'subscribed and 9am (in user timezone)' do
      create(:user, timezone: 'Singapore', email_preferences: { daily_reports: '1' })

      travel_to Time.parse('May 20, 2016 09:00 +0800') do
        service.send_now

        expect(ReportsMailer).to have_received(:daily_summary)
      end
    end

    it 'unsubscribed user' do
      create(:user, timezone: 'Singapore', email_preferences: { daily_reports: '0' })

      travel_to Time.parse('May 20, 2016 09:00 +0800') do
        service.send_now

        expect(ReportsMailer).to_not have_received(:daily_summary)
      end
    end

    it 'not 9am' do
      create(:user, timezone: 'Singapore', email_preferences: { daily_reports: '1' })

      travel_to Time.parse('May 20, 2016 10:00 +0800') do
        service.send_now

        expect(ReportsMailer).to_not have_received(:daily_summary)
      end
    end
  end
end

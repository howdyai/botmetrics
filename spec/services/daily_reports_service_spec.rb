RSpec.describe DailyReportsService do
  describe '#send_now' do
    let(:service) { DailyReportsService.new }

    before { allow(ReportsMailer).to receive(:daily_summary) { double(:mail).as_null_object } }

    def create_singaporean(options = {})
      create(:user, timezone: 'Singapore', **options)
    end

    it 'unsubscribed user' do
      create_singaporean(email_preferences: { daily_reports: '0' })

      travel_to Time.parse('May 20, 2016 09:00 +0800') do
        service.send_now

        expect(ReportsMailer).to_not have_received(:daily_summary)
      end
    end

    it 'not sent, subscribed and 9am (in user timezone)' do
      travel_to Time.parse('May 20, 2016 09:00 +0800') do
        create_singaporean(
          email_preferences: { daily_reports: '1' },
          tracking_attributes: {
            last_daily_summary_sent_at: (24.hours.ago - 1.second).to_i
          }
        )

        service.send_now

        expect(ReportsMailer).to have_received(:daily_summary)
      end
    end

    it 'sent still in 24-hour window, subscribed, 9 am (in user timezone)' do
      travel_to Time.parse('May 20, 2016 09:00 +0800') do
        create_singaporean(
          email_preferences: { daily_reports: '1' },
          tracking_attributes: { last_daily_summary_sent_at: (24.hours.ago + 1.second).to_i }
        )

        service.send_now

        expect(ReportsMailer).to_not have_received(:daily_summary)
      end
    end
  end
end

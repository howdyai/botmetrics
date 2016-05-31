RSpec.describe ReportsMailer do
  let(:bot)  { double(:bot, name: 'Bot', instances: BotInstance.all) }
  let!(:enabled) { create(:bot_instance, :with_attributes, uid: 'B123', state: 'enabled') }
  let!(:pending) { create(:bot_instance, :with_attributes, uid: 'B456', state: 'pending') }

  before do
    allow(User).to receive(:find) { user }
    allow(Dashboarder).to receive(:new) do
      double(
        :dashboard,
        new_bots_growth: {},
        disabled_bots_growth: {},
        new_users_growth: {},
        messages_growth: {},
        messages_for_bot_growth: {},
        messages_from_bot_growth: {},
      ).as_null_object
    end
  end

  describe '#daily_summary' do
    let(:user) { double(:user, id: 1, email: 'a@example.com', timezone: 'Singapore', bots: [bot]) }

    it 'send email to bot owners' do
      mail = ReportsMailer.daily_summary(user.id)

      expect(mail.to).to      eq [user.email]
      expect(mail.subject).to match 'Daily Summary'

      expect(mail.body.encoded).to match bot.name

      expect(Dashboarder).to have_received(:new).with(contain_exactly(enabled), 'today', 'Singapore', false)
    end

    context 'weeky summary' do
      it 'has weekly summary if monday' do
        travel_to Time.parse('23 May, 2016 09:00 +0800') do
          mail = ReportsMailer.daily_summary(user.id)

          expect(mail.body.encoded).to match 'Weekly Summary'
        end
      end

      it 'does not have weekly summary on non-mondays' do
        travel_to Time.parse('24 May, 2016 09:00 +0800') do
          mail = ReportsMailer.daily_summary(user.id)

          expect(mail.body.encoded).to_not match 'Weekly Summary'
        end
      end
    end
  end
end

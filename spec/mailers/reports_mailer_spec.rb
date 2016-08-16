RSpec.describe ReportsMailer do
  let(:bot1)  { double(:bot, name: 'Bot', provider: 'slack', instances: BotInstance.where(id: [enabled1.id, pending1.id])) }
  let(:bot2)  { double(:bot, name: 'Bot', provider: 'facebook', instances: BotInstance.where(id: [enabled2.id, pending2.id])) }

  let!(:enabled1) { create(:bot_instance, :with_attributes, uid: 'B123', state: 'enabled') }
  let!(:enabled2) { create(:bot_instance, :with_attributes, uid: 'B345', state: 'enabled') }
  let!(:pending1) { create(:bot_instance, :with_attributes, uid: 'B456', state: 'pending') }
  let!(:pending2) { create(:bot_instance, :with_attributes, uid: 'B678', state: 'pending') }

  before do
    allow(User).to receive(:find) { user }
    allow(user).to receive(:log_daily_summary_sent)
    allow(Dashboarder).to receive(:new) do
      double(
        :dashboard,
        new_bots_growth: 0.5,
        disabled_bots_growth: 0.5,
        new_users_growth: 0.5,
        messages_growth: 0.5,
        messages_for_bot_growth: 0.5,
        messages_from_bot_growth: 0.5,
      ).as_null_object
    end
  end

  describe '#daily_summary' do
    let(:user) { double(:user, id: 1, email: 'a@example.com', timezone: 'Singapore', bots: [bot1, bot2]) }

    it 'send email to bot owners' do
      mail = ReportsMailer.daily_summary(user.id)

      expect(mail.to).to      eq [user.email]
      expect(mail.subject).to match 'Daily Summary'

      expect(mail.body.encoded).to match bot1.name
      expect(mail.body.encoded).to match bot2.name

      expect(Dashboarder).to have_received(:new).with(contain_exactly(enabled1), 'today', 'Singapore', false)
      expect(Dashboarder).to have_received(:new).with(contain_exactly(enabled2), 'today', 'Singapore', false)
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

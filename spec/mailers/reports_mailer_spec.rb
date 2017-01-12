RSpec.describe ReportsMailer do
  let!(:bot1)  { create :bot, name: 'Slack Bot', provider: 'slack' }
  let!(:bot2)  { create :bot, name: 'Facebook Bot', provider: 'facebook' }
  let!(:bot3)  { create :bot, name: 'Facebook Bot 2', provider: 'facebook', enabled: false }

  let!(:enabled1) { create(:bot_instance, :with_attributes, uid: 'B123', bot: bot1, state: 'enabled') }
  let!(:enabled2) { create(:bot_instance, :with_attributes, uid: 'B345', bot: bot2, state: 'enabled') }
  let!(:pending1) { create(:bot_instance, :with_attributes, uid: 'B456', bot: bot1, state: 'pending') }
  let!(:pending2) { create(:bot_instance, :with_attributes, uid: 'B678', bot: bot2, state: 'pending') }

  before do
    allow(User).to receive(:find) { user }
    allow(user).to receive(:log_daily_summary_sent)
  end

  describe '#daily_summary' do
    let!(:user) { create :user, timezone: 'Singapore' }
    let!(:bc1) { create :bot_collaborator, bot: bot1, user: user }
    let!(:bc2) { create :bot_collaborator, bot: bot2, user: user }
    let!(:bc3) { create :bot_collaborator, bot: bot3, user: user }

    it 'sends email to bot owners' do
      mail = ReportsMailer.daily_summary(user.id)

      expect(mail.to).to      eq [user.email]
      expect(mail.subject).to match 'Daily Summary'

      expect(mail.body.encoded).to match bot1.name
      expect(mail.body.encoded).to match bot2.name
      expect(mail.body.encoded).to_not match bot3.name
    end

    context 'weekly summary' do
      it 'has weekly summary if monday' do
        # May 23, is Monday
        Timecop.travel Time.parse('23 May, 2016 09:00 +0800') do
          mail = ReportsMailer.daily_summary(user.id)

          expect(mail.body.encoded).to match 'Weekly Summary'
        end
      end

      it 'does not have weekly summary on non-mondays' do
        # May 24, is Tuesday
        Timecop.travel Time.parse('24 May, 2016 09:00 +0800') do
          mail = ReportsMailer.daily_summary(user.id)

          expect(mail.body.encoded).to_not match 'Weekly Summary'
        end
      end
    end
  end
end

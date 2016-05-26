RSpec.describe ReportsMailer do
  let(:bot)  { double(:bot, name: 'Bot', instances: [bot_instance]) }
  let(:bot_instance) do
    double(
      :bot_instance,
      id: 1,
      team_name: 'T123', team_url: 'T123.slack.com'
    )
  end

  before do
    allow(User).to receive(:find) { user }
    allow(::Dashboarder).to receive(:new) do
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

      expect(::Dashboarder).to have_received(:new).with([bot_instance], 'today', 'Singapore', false)
    end
  end
end

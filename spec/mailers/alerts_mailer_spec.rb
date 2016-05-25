RSpec.describe AlertsMailer do
  describe '#created_bot_instance' do
    let(:bot)    { double(:bot, name: 'Bot') }
    let(:owners) { [double(:owner, email: 'a@example.com'), double(:owner, email: 'b@example.com')] }

    let(:bot_instance) do
      double(
        :bot_instance,
        id: 1,
        bot: bot,
        owners: owners,
        team_name: 'T123', team_url: 'T123.slack.com',
        users: [double(:user), double(:user)]
      )
    end
    let(:user) { double(:user, id: 11, full_name: 'John') }

    before do
      allow(BotInstance).to receive(:find) { bot_instance }
      allow(User).to receive(:find) { user }
    end

    it 'send email to bot owners' do
      mail = AlertsMailer.created_bot_instance(bot_instance.id, user.id)

      expect(mail.to).to      eq bot_instance.owners.map(&:email)
      expect(mail.subject).to match bot.name

      expect(mail.body.encoded).to match user.full_name
      expect(mail.body.encoded).to match bot_instance.team_name
      expect(mail.body.encoded).to match bot_instance.team_url
    end
  end
end

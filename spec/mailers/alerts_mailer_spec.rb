RSpec.describe AlertsMailer do
  let(:bot) { double(:bot, name: 'Bot') }
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

  describe '#created_bot_instance' do
    context 'with all owners subscribed' do
      let(:owners) do
        create_list(:user, 2)
        User.all # returns as ActiveRecord query so the stub works
      end

      it 'send email to bot owners' do
        mail = AlertsMailer.created_bot_instance(bot_instance.id, user.id)

        expect(mail.to).to      eq bot_instance.owners.map(&:email)
        expect(mail.to.size).to eq 2
        expect(mail.subject).to match bot.name

        expect(mail.body.encoded).to match user.full_name
        expect(mail.body.encoded).to match bot_instance.team_name
        expect(mail.body.encoded).to match bot_instance.team_url
      end
    end

    context 'with some owners subscribed' do
      let(:owners) do
        create(:user, created_bot_instance: '0')
        create(:user, created_bot_instance: '1')
        User.all # returns as ActiveRecord query so the stub works
      end

      it 'send email to bot owners' do
        mail = AlertsMailer.created_bot_instance(bot_instance.id, user.id)

        expect(mail.to.size).to eq 1
        expect(mail.subject).to match bot.name

        expect(mail.body.encoded).to match user.full_name
        expect(mail.body.encoded).to match bot_instance.team_name
        expect(mail.body.encoded).to match bot_instance.team_url
      end
    end
  end

  describe '#disabled_bot_instance' do
    context 'with all owners subscribed' do
      let(:owners) do
        create_list(:user, 2)
        User.all # returns as ActiveRecord query so the stub works
      end

      it 'sends email to bot owners' do
        mail = AlertsMailer.disabled_bot_instance(bot_instance.id)

        expect(mail.to).to      eq bot_instance.owners.map(&:email)
        expect(mail.to.size).to eq 2
        expect(mail.subject).to match bot.name

        expect(mail.body.encoded).to match bot_instance.team_name
        expect(mail.body.encoded).to match bot_instance.team_url
      end
    end

    context 'with some owners subscribed' do
      let(:owners) do
        create(:user, disabled_bot_instance: '0')
        create(:user, disabled_bot_instance: '1')
        User.all # returns as ActiveRecord query so the stub works
      end

      it 'sends email to bot owners' do
        mail = AlertsMailer.disabled_bot_instance(bot_instance.id)

        expect(mail.to.size).to eq 1
        expect(mail.subject).to match bot.name

        expect(mail.body.encoded).to match bot_instance.team_name
        expect(mail.body.encoded).to match bot_instance.team_url
      end
    end
  end
end

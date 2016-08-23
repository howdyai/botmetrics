RSpec.describe RelaxService do
  let!(:admin_user)  { create :user }
  let!(:parent_bot)  { create :bot  }
  let!(:bc1)         { create :bot_collaborator, bot: parent_bot, user: admin_user }

  before do
    allow(SendEventToWebhookJob).to receive(:perform_async)
    allow(SetMixpanelPropertyJob).to receive(:perform_async)
  end

  shared_examples "calls the webhook if it is setup and doesn't if it is not" do
    context "bot doesn't has a webhook_url set up" do
      before { bi.bot.update_attribute(:webhook_url, nil) }

      it 'should NOT call SendEventToWebhookJob' do
        RelaxService.handle(event)
        expect(SendEventToWebhookJob).to_not have_received(:perform_async)
      end
    end

    context 'bot has a webhook_url set up' do
      before { bi.bot.update_attribute(:webhook_url, 'https://test.host/webhooks') }

      it 'should call SendEventToWebhookJob' do
        RelaxService.handle(event)
        expect(SendEventToWebhookJob).to have_received(:perform_async).with(bi.bot_id, event.to_json)
      end
    end
  end

  shared_examples "sets the mixpanel property 'received_first_event' if first_received_event_at is nil" do
    context "first_received_event_at is not nil" do
      it 'should update first_received_event_at and set the property on Mixpanel' do
        expect {
          RelaxService.handle(event)
          parent_bot.reload
        }.to change(parent_bot, :first_received_event_at)
      end

      it 'should set the mixpanel property "received_first_event" to true' do
        RelaxService.handle(event)
        expect(SetMixpanelPropertyJob).to have_received(:perform_async).with(admin_user.id, 'received_first_event', true)
      end
    end

    context "first_received_event_at is NOT nil" do
      before { parent_bot.update_attribute(:first_received_event_at, Time.now) }

      it 'should NOT update first_received_event_at and set the property on Mixpanel' do
        expect {
          RelaxService.handle(event)
          parent_bot.reload
        }.to_not change(parent_bot, :first_received_event_at)
      end

      it 'should NOT set the mixpanel property "received_first_event" to true' do
        RelaxService.handle(event)
        expect(SetMixpanelPropertyJob).to_not have_received(:perform_async).with(admin_user.id, 'received_first_event', true)
      end
    end
  end

  describe 'team_joined' do
    let!(:event) { Relax::Event.new(team_uid: 'TDEADBEEF', namespace: 'UNESTOR1', type: 'team_joined') }

    before { allow(ImportUsersForBotInstanceJob).to receive(:perform_async) }

    context 'bot instance exists' do
      let!(:bi) { create :bot_instance, bot: parent_bot, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'enabled' }

      it 'should call ImportUsersForBotInstanceJob' do
        RelaxService.handle(event)
        expect(ImportUsersForBotInstanceJob).to have_received(:perform_async).with(bi.id)
      end

      it 'should create a new event' do
        expect {
          RelaxService.handle(event)
          bi.reload
        }.to change(bi.events, :count).by(1)

        e = bi.events.last
        expect(e.event_type).to eql 'user_added'
        expect(e.provider).to eql 'slack'
      end

      it_behaves_like "calls the webhook if it is setup and doesn't if it is not"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"
    end

    context 'bot instance does not exist' do
      it 'should NOT call ImportUsersForBotInstanceJob' do
        RelaxService.handle(event)
        expect(ImportUsersForBotInstanceJob).to_not have_received(:perform_async)
      end
    end
  end

  describe 'disable_bot' do
    let!(:event) { Relax::Event.new(team_uid: 'TDEADBEEF', namespace: 'UNESTOR1', type: 'disable_bot') }

    before { allow(Alerts::DisabledBotInstanceJob).to receive(:perform_async) }

    context 'bot instance exists' do
      let!(:bi) { create :bot_instance, bot: parent_bot, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'enabled' }

      it 'should disable the bot' do
        expect {
          RelaxService.handle(event)
          bi.reload
        }.to change(bi, :state).from('enabled').to('disabled')
      end

      it 'should create a new event' do
        expect {
          RelaxService.handle(event)
          bi.reload
        }.to change(bi.events, :count).by(1)

        e = bi.events.last
        expect(e.event_type).to eql 'bot_disabled'
        expect(e.provider).to eql 'slack'
      end

      it 'should send an alert' do
        RelaxService.handle(event)

        expect(Alerts::DisabledBotInstanceJob).to have_received(:perform_async).with(bi.id)
      end

      it_behaves_like "calls the webhook if it is setup and doesn't if it is not"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"
    end
  end

  describe 'message reaction' do
    let!(:event) do
      Relax::Event.new(
        team_uid: 'TCAFEDEAD',
        user_uid: 'UDEADBEEF1',
        channel_uid: 'DCAFEDEAD1',
        timestamp: '123456789.0',
        provider: 'slack',
        im: false,
        text: ':+1:',
        relax_bot_uid: 'UNESTOR1',
        namespace: 'UNESTOR1',
        type: 'reaction_added'
      )
    end

    let!(:user) { create :bot_user, uid: 'UDEADBEEF1', provider: 'slack', bot_instance: bi }
    let!(:bot)  { create :bot_user, uid: 'UNESTOR1', provider: 'slack', bot_instance: bi }

    context 'bot instance exists' do
      let!(:bi) { create :bot_instance, bot: parent_bot, uid: 'UNESTOR1', instance_attributes: { team_id: 'TCAFEDEAD', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'enabled' }


      context 'when message is not meant for the bot' do
        it 'should create a new event' do
          expect {
            RelaxService.handle(event)
            bi.reload
          }.to change(bi.events, :count).by(1)

          e = bi.events.last

          expect(e.event_type).to eql 'message_reaction'
          expect(e.user).to eql user
          expect(e.provider).to eql 'slack'
          expect(e.event_attributes['channel']).to eql 'DCAFEDEAD1'
          expect(e.event_attributes['timestamp']).to eql '123456789.0'
          expect(e.event_attributes['reaction']).to eql ':+1:'
          expect(e.is_from_bot).to be_falsey
          expect(e.is_im).to be_falsey
          expect(e.is_for_bot).to be_falsey
          expect(e.created_at.to_f).to eql event.timestamp.to_f
          expect(e.has_been_read).to be true
          expect(e.has_been_delivered).to be true
        end

        it_behaves_like "calls the webhook if it is setup and doesn't if it is not"
        it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"
      end
    end
  end

  describe 'message' do
    let!(:event) do
      Relax::Event.new(
        team_uid: 'TCAFEDEAD',
        user_uid: 'UDEADBEEF1',
        channel_uid: 'DCAFEDEAD1',
        timestamp: '123456789.0',
        provider: 'slack',
        im: false,
        text: 'thanks',
        relax_bot_uid: 'UNESTOR1',
        namespace: 'UNESTOR1',
        type: 'message_new'
      )
    end
    let!(:user) { create :bot_user, uid: 'UDEADBEEF1', provider: 'slack', bot_instance: bi }
    let!(:bot)  { create :bot_user, uid: 'UNESTOR1', provider: 'slack', bot_instance: bi }

    shared_examples "associates event with custom dashboard if custom dashboards exist" do
      let!(:dashboard1) { create :dashboard, bot: bi.bot, regex: 'thanks', dashboard_type: 'custom', provider: 'slack' }
      let!(:dashboard2) { create :dashboard, bot: bi.bot, regex: 'nks', dashboard_type: 'custom', provider: 'slack' }
      let!(:dashboard3) { create :dashboard, bot: bi.bot, regex: 'welcome', dashboard_type: 'custom', provider: 'slack' }

      it 'should associate events with dashboards that match the text' do
        RelaxService.handle(event)
        dashboard1.reload; dashboard2.reload; dashboard3.reload
        e = bi.events.last

        expect(dashboard1.events.to_a).to eql [e]
        expect(dashboard2.events.to_a).to eql [e]
        expect(dashboard3.events.to_a).to be_empty
      end
    end

    context 'bot instance exists' do
      let!(:bi) { create :bot_instance, bot: parent_bot, uid: 'UNESTOR1', instance_attributes: { team_id: 'TCAFEDEAD', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'enabled' }

      context 'when message is not meant for the bot' do
        it 'should create a new event' do
          expect {
            RelaxService.handle(event)
            bi.reload
          }.to change(bi.events, :count).by(1)

          e = bi.events.last

          expect(e.event_type).to eql 'message'
          expect(e.user).to eql user
          expect(e.provider).to eql 'slack'
          expect(e.event_attributes['channel']).to eql 'DCAFEDEAD1'
          expect(e.event_attributes['timestamp']).to eql '123456789.0'
          expect(e.is_from_bot).to be_falsey
          expect(e.is_im).to be_falsey
          expect(e.is_for_bot).to be_falsey
          expect(e.text).to be_nil
          expect(e.created_at.to_f).to eql event.timestamp.to_f
          expect(e.has_been_read).to be true
          expect(e.has_been_delivered).to be true
        end

        it 'should not change BotUser#last_interacted_with_bot_at & BotUser#bot_interaction_count' do
          RelaxService.handle(event)
          user.reload
          expect(user.bot_interaction_count).to eql 0
          expect(user.last_interacted_with_bot_at).to be_nil
        end

        it_behaves_like "calls the webhook if it is setup and doesn't if it is not"
        it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"

        context 'when message is from the bot' do
          before do
            event.user_uid = 'UNESTOR1'
          end

          it 'should create a new event with is_from_bot to as true' do
            expect {
              RelaxService.handle(event)
              bi.reload
            }.to change(bi.events, :count).by(1)

            e = bi.events.last

            expect(e.event_type).to eql 'message'
            expect(e.user).to eql bot
            expect(e.provider).to eql 'slack'
            expect(e.event_attributes['channel']).to eql 'DCAFEDEAD1'
            expect(e.event_attributes['timestamp']).to eql '123456789.0'
            expect(e.is_from_bot).to be_truthy
            expect(e.is_im).to be_falsey
            expect(e.is_for_bot).to be_falsey
            expect(e.text).to eql 'thanks'
            expect(e.created_at.to_f).to eql event.timestamp.to_f
            expect(e.has_been_read).to be true
            expect(e.has_been_delivered).to be true
          end

          it 'should not change BotUser#last_interacted_with_bot_at & BotUser#bot_interaction_count' do
            RelaxService.handle(event)
            user.reload
            expect(user.bot_interaction_count).to eql 0
            expect(user.last_interacted_with_bot_at).to be_nil
          end

          it_behaves_like "calls the webhook if it is setup and doesn't if it is not"
        end
      end

      context 'when message is an IM' do
        before { event.im = true }

        it 'should create a new event' do
          expect {
            RelaxService.handle(event)
            bi.reload
          }.to change(bi.events, :count).by(1)

          e = bi.events.last

          expect(e.event_type).to eql 'message'
          expect(e.user).to eql user
          expect(e.provider).to eql 'slack'
          expect(e.event_attributes['channel']).to eql 'DCAFEDEAD1'
          expect(e.event_attributes['timestamp']).to eql '123456789.0'
          expect(e.is_from_bot).to be_falsey
          expect(e.is_im).to be_truthy
          expect(e.is_for_bot).to be_truthy
          expect(e.text).to eql 'thanks'
          expect(e.created_at.to_f).to eql event.timestamp.to_f
          expect(e.has_been_read).to be true
          expect(e.has_been_delivered).to be true
        end

        it 'should change BotUser#last_interacted_with_bot_at & BotUser#bot_interaction_count' do
          RelaxService.handle(event)
          user.reload
          expect(user.bot_interaction_count).to eql 1
          expect(user.last_interacted_with_bot_at.to_f).to eql event.timestamp.to_f
        end

        it_behaves_like "calls the webhook if it is setup and doesn't if it is not"
        it_behaves_like "associates event with custom dashboard if custom dashboards exist"
        it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"

        context 'when message is from the bot' do
          before do
            event.user_uid = 'UNESTOR1'
          end

          it 'should create a new event with is_from_bot to as true' do
            expect {
              RelaxService.handle(event)
              bi.reload
            }.to change(bi.events, :count).by(1)

            e = bi.events.last

            expect(e.event_type).to eql 'message'
            expect(e.user).to eql bot
            expect(e.provider).to eql 'slack'
            expect(e.event_attributes['channel']).to eql 'DCAFEDEAD1'
            expect(e.event_attributes['timestamp']).to eql '123456789.0'
            expect(e.is_from_bot).to be_truthy
            expect(e.is_im).to be_truthy
            # is_for_bot will be falsey if it is_from_bot
            expect(e.is_for_bot).to be_falsey
            expect(e.text).to eql 'thanks'
            expect(e.created_at.to_f).to eql event.timestamp.to_f
            expect(e.has_been_read).to be true
            expect(e.has_been_delivered).to be true
          end

          it 'should not change BotUser#last_interacted_with_bot_at & BotUser#bot_interaction_count' do
            RelaxService.handle(event)
            user.reload
            expect(user.bot_interaction_count).to eql 0
            expect(user.last_interacted_with_bot_at).to be_nil
          end

          it_behaves_like "calls the webhook if it is setup and doesn't if it is not"
          it_behaves_like "associates event with custom dashboard if custom dashboards exist"
        end
      end

      context 'when message is not an IM but meant for the bot' do
        before { event.text = 'thanks <@UNESTOR1>!' }

        it 'should create a new event' do
          expect {
            RelaxService.handle(event)
            bi.reload
          }.to change(bi.events, :count).by(1)

          e = bi.events.last

          expect(e.event_type).to eql 'message'
          expect(e.user).to eql user
          expect(e.provider).to eql 'slack'
          expect(e.event_attributes['channel']).to eql 'DCAFEDEAD1'
          expect(e.event_attributes['timestamp']).to eql '123456789.0'
          expect(e.is_from_bot).to be_falsey
          expect(e.is_im).to be_falsey
          expect(e.is_for_bot).to be_truthy
          expect(e.text).to eql 'thanks <@UNESTOR1>!'
          expect(e.created_at.to_f).to eql event.timestamp.to_f
          expect(e.has_been_read).to be true
          expect(e.has_been_delivered).to be true
        end

        it 'should change BotUser#last_interacted_with_bot_at & BotUser#bot_interaction_count' do
          RelaxService.handle(event)
          user.reload
          expect(user.bot_interaction_count).to eql 1
          expect(user.last_interacted_with_bot_at.to_f).to eql event.timestamp.to_f
        end

        it_behaves_like "calls the webhook if it is setup and doesn't if it is not"
        it_behaves_like "associates event with custom dashboard if custom dashboards exist"
        it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"

        context 'when message is from the bot' do
          before do
            event.user_uid = 'UNESTOR1'
          end

          it 'should create a new event with is_from_bot to as true' do
            expect {
              RelaxService.handle(event)
              bi.reload
            }.to change(bi.events, :count).by(1)

            e = bi.events.last

            expect(e.event_type).to eql 'message'
            expect(e.user).to eql bot
            expect(e.provider).to eql 'slack'
            expect(e.event_attributes['channel']).to eql 'DCAFEDEAD1'
            expect(e.event_attributes['timestamp']).to eql '123456789.0'
            expect(e.is_from_bot).to be_truthy
            expect(e.is_im).to be_falsey
            # is_for_bot will be falsey if it is_from_bot
            expect(e.is_for_bot).to be_falsey
            expect(e.text).to eql 'thanks <@UNESTOR1>!'
            expect(e.created_at.to_f).to eql event.timestamp.to_f
            expect(e.has_been_read).to be true
            expect(e.has_been_delivered).to be true
          end

          it 'should not change BotUser#last_interacted_with_bot_at & BotUser#bot_interaction_count' do
            RelaxService.handle(event)
            user.reload
            expect(user.bot_interaction_count).to eql 0
            expect(user.last_interacted_with_bot_at).to be_nil
          end

          it_behaves_like "calls the webhook if it is setup and doesn't if it is not"
          it_behaves_like "associates event with custom dashboard if custom dashboards exist"
          it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"
        end
      end
    end
  end
end

require 'spec_helper'

describe RelaxService do
  describe 'team_joined' do
    let!(:event) { Relax::Event.new(team_uid: 'TDEADBEEF', namespace: 'UNESTOR1', type: 'team_joined') }
    before { allow(ImportUsersForBotInstanceJob).to receive(:perform_async) }

    context 'bot instance exists' do
      let!(:bi) { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'enabled' }

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

    context 'bot instance exists' do
      let!(:bi) { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'enabled' }

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

    context 'bot instance exists' do
      let!(:bi) { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TCAFEDEAD', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'enabled' }

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
          expect(e.is_im).to be_falsey
          expect(e.is_for_bot).to be_falsey
        end
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

    context 'bot instance exists' do
      let!(:bi) { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TCAFEDEAD', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'enabled' }

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
          expect(e.is_im).to be_falsey
          expect(e.is_for_bot).to be_falsey
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
          expect(e.is_im).to be_truthy
          expect(e.is_for_bot).to be_truthy
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
          expect(e.is_im).to be_falsey
          expect(e.is_for_bot).to be_truthy
        end
      end
    end
  end
end

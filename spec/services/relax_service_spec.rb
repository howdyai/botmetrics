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
end

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
    end
  end
end

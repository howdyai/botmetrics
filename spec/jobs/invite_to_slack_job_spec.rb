RSpec.describe InviteToSlackJob do
  describe '#perform' do
    let!(:user) { create :user, email: 'i@mclov.in', full_name: 'Mclovin' }

    context 'when there is a valid response from Slack' do
      before do
        Timecop.freeze
        allow(SlackInviter).to receive(:invite).with('i@mclov.in', 'Mclovin').and_return('ok' => true)
        @now = Time.now
      end

      after do
        Timecop.return
      end

      it 'should update the invited_to_slack_at attribute' do
        InviteToSlackJob.new.perform(user.id)
        user.reload
        expect(user.invited_to_slack_at.to_i).to eql(@now.to_i)
      end

      it 'should update the slack_invite_response' do
        InviteToSlackJob.new.perform(user.id)
        user.reload
        expect(user.slack_invite_response).to eql('ok' => true)
      end
    end

    context 'when there is an invalid response from Slack' do
      before do
        Timecop.freeze
        allow(SlackInviter).to receive(:invite).with('i@mclov.in', 'Mclovin').and_return('ok' => false, 'error' => 'invalid email')
        @now = Time.now
      end

      after do
        Timecop.return
      end

      it 'should NOT update the invited_to_slack_at attribute' do
        InviteToSlackJob.new.perform(user.id)
        user.reload
        expect(user.invited_to_slack_at).to be_nil
      end

      it 'should update the slack_invite_response' do
        InviteToSlackJob.new.perform(user.id)
        user.reload
        expect(user.slack_invite_response).to eql('ok' => false, 'error' => 'invalid email')
      end
    end
  end
end

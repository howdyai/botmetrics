require 'rails_helper'

RSpec.describe InvitationsController, type: :controller do
  before :each do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'POST#create' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot  }
    let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }

    let!(:invite_attributes) do
      {
        email: 'x@mclov.in',
        full_name: 'Mclovin',
        timezone: 'Pacific Time (US & Canada)',
        bot_id: bot.uid
      }
    end

    before do
      allow(TrackMixpanelEventJob).to receive(:perform_async)
      sign_in user
    end

    def do_request
      post :create, invite: invite_attributes
    end

    it 'creates a new user invited by the signed in user' do
      expect { do_request }.to change(User, :count).by(1)

      invited_user = User.last
      expect(invited_user.full_name).to eql 'Mclovin'
      expect(invited_user.email).to eql 'x@mclov.in'
      expect(invited_user.timezone).to eql 'Pacific Time (US & Canada)'
      expect(invited_user.timezone_utc_offset).to eql -28800
      expect(invited_user.invited_by).to eql user
      expect(invited_user.invitation_token).to_not be_nil
    end

    it 'creates a new "unconfirmed" bot collaborator model' do
      expect {
        do_request
        bot.reload
      }.to change(bot.collaborators, :count).by(1)

      bc = BotCollaborator.last
      expect(bc.user).to eql User.last
      expect(bc.bot).to eql bot
      expect(bc.confirmed_at).to be_nil
      expect(bc.collaborator_type).to eql 'member'
    end

    it 'should track the event on Mixpanel' do
      do_request
      expect(TrackMixpanelEventJob).to have_received(:perform_async).with('Invited Collaborator to Bot', user.id, bot_id: bot.uid)
    end
  end
end

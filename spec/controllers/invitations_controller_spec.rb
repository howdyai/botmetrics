require 'rails_helper'

RSpec.describe InvitationsController, type: :controller do
  before :each do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'POST#create' do
    let!(:user) { create :user }
    let!(:bot)  { create :bot  }
    let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }
    let!(:message_delivery) { double(ActionMailer::MessageDelivery) }

    let!(:invite_attributes) do
      {
        email: 'x@mclov.in',
        full_name: 'Mclovin',
        timezone: 'Pacific Time (US & Canada)',
        bot_id: bot.uid
      }
    end

    before do
      allow(InvitesMailer).to receive(:invite_to_collaborate).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_later)
      sign_in user
    end

    def do_request
      post :create, invite: invite_attributes
    end

    context 'user does not exist' do
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

      it 'does not send the email meant for an existing user' do
        do_request
        expect(message_delivery).to_not have_received(:deliver_later)
      end
    end

    context 'user does exist' do
      let!(:existing_user) { create :user, email: 'x@mclov.in' }

      it "doesn't create a new user" do
        expect { do_request }.to_not change(User, :count)
      end

      it 'creates a new "confirmed" bot collaborator model' do
        expect {
          do_request
          bot.reload
        }.to change(bot.collaborators, :count).by(1)

        bc = BotCollaborator.last
        expect(bc.user).to eql existing_user
        expect(bc.bot).to eql bot
        expect(bc.confirmed_at).to_not be_nil
        expect(bc.collaborator_type).to eql 'member'
      end

      it 'should send the email meant for an existing user' do
        do_request
        expect(InvitesMailer).to have_received(:invite_to_collaborate).with(User.last.id, user.id, bot.id)
        expect(message_delivery).to have_received(:deliver_later)
      end
    end
  end

  describe 'PATCH#update' do
    let!(:user) { create :user, signed_up_at: nil }
    let!(:inviting_user) { create :user }

    let!(:bot) { create :bot }
    let!(:bc1) { create :bot_collaborator, bot: bot, user: inviting_user, confirmed_at: Time.now }
    let!(:bc2) { create :bot_collaborator, bot: bot, user: user }

    before do
      user.invite!(inviting_user)
      user.send(:generate_invitation_token)
      @invitation_token = user.instance_variable_get('@raw_invitation_token')
      user.save(validate: false)
    end

    def do_request
      patch :update, user: { invitation_token: @invitation_token, password: 'password123', password_confirmation: 'password123' }
    end

    it 'should update the confirmed_at for bot collaborations that are not yet confirmed' do
      expect {
        do_request
        bc2.reload
      }.to change(bc2, :confirmed_at).from(nil)
    end

    it 'should set signed_up_at on User' do
      expect {
        do_request
        user.reload
      }.to change(user, :signed_up_at).from(nil)
    end
  end
end

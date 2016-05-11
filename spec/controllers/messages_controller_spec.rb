require 'rails_helper'

RSpec.describe MessagesController do
  let!(:bot)          { create :bot}
  let!(:bot_instance) { create :bot_instance, bot: bot, instance_attributes: { team_id: team_id } }
  let!(:team_id)      { 'ABC-123' }

  describe '#create' do
    def do_request
      post :create, { bot_id: bot.uid }.merge(params)
    end

    context 'success' do
      let(:params) { { message: { team_id: team_id, channel: 'abc123', text: 'Hello World'} } }

      before { allow(SendMessageJob).to receive(:perform_async) }

      it 'sends message and returns success' do
        do_request

        expect(SendMessageJob).to have_received(:perform_async).with(Message.last.id)
        expect(Message.last.bot_instance).to eq bot_instance
        expect(response.status).to eq 202
      end
    end

    context 'failure' do
      context 'missing bot instance' do
        let(:params) { { message: { team_id: 'not-found', channel: 'general', text: 'Hello World'} } }

        it 'returns 404' do
          do_request

          expect(response.status).to eq 404
        end
      end

      context 'invalid message' do
        let(:params) { { message: { team_id: team_id, channel: nil, text: 'Hello World'} } }

        it 'does not sends message' do
          expect(SendMessageJob).to_not receive(:perform_async)

          do_request
        end

        it 'returns failure' do
          do_request

          expect(response.status).to eq 400
        end
      end
    end
  end
end

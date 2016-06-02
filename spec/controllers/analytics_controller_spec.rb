RSpec.describe AnalyticsController do
  describe '#index' do
    let!(:user)   { create :user }
    let!(:bot)    { create(:bot) }
    let!(:collab) { create :bot_collaborator, bot: bot, user: user }

    def do_request
      get :index, { bot_id: bot.to_param }.merge(params)
    end

    before { sign_in user }

    context 'without params' do
      let(:params) { {} }

      it 'success' do
        allow(TrackMixpanelEventJob).to receive(:perform_async).
          with('Viewed Analytics Index Page', user.id)

        do_request

        expect(response).to be_success
      end
    end

    context 'with params' do
      let(:queries_attributes) { { queries_attributes: { '0' => { field: 'nickname', method: 'equals_to', value: 'john' } } } }
      let(:params) { { query_set: queries_attributes } }

      it 'filters' do
        allow(TrackMixpanelEventJob).to receive(:perform_async).
          with(
            'Viewed Analytics Index Page and Performed Queries',
            user.id,
            query_attributes: queries_attributes
          )

        do_request

        expect(response).to be_success
      end
    end
  end
end

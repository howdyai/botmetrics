require 'rails_helper'

RSpec.describe ShortLinksController, type: :controller do

  let!(:user) { create :user }
  let!(:bot)          { create :bot}
  let!(:bot_instance) { create :bot_instance, bot: bot}
  let!(:bot_user) {create :bot_user, bot_instance: bot_instance}
  let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }
  let!(:url) {'http://www.google.com'}
  
  before do
    sign_in user
  end

  describe '#create' do

    def do_request
      post :create, params
    end

    context 'success' do
      let(:params) { { url:url, bot_user_id: bot_user.uid, bot_id: bot.uid  } }
      it "returns a shortened link" do
        expect {
          do_request
          bot_instance.reload
          }.to change(bot_instance.short_links,:count).by(1)

          short_link = bot_instance.short_links.last
          expect(short_link.bot_user).to eql bot_user
          expect(short_link.url).to eql url
          expect(short_link.slug).to_not be_empty
        end
      it "returns 200" do
        do_request
        expect(response.status).to eq 200
      end
    end

    context 'failure' do
      context 'missing bot id' do
        let(:params) { { url:url, bot_user_id: bot_user.uid, bot_id: ''  }  }

        it 'does not create a ShortLink'do
          do_request
          expect(ShortLink.count).to eq 0
        end

        it 'returns 404' do
          do_request
          expect(response.status).to eq 404
        end
      end

      context 'missing url' do
        let(:params) { { url:'', bot_user_id: bot_user.uid, bot_id: bot.uid  } }

        it 'does not create a ShortLink'do
          do_request
          expect(ShortLink.count).to eq 0
        end

        it 'returns 404' do
          do_request
          expect(response.status).to eq 404
        end
      end
    end
  end

  describe '#show' do
    def do_request()
    get :show, params
    end

    context "slug exists" do
      let(:sl) {create :short_link, bot_instance: bot_instance, bot_user: bot_user, url: url}
      let(:params) {{id: sl.slug}}

      it "redirects to URL" do 
        do_request
        expect(response).to redirect_to(sl.url)
      end
    end
    context "slug doesn't exist" do
      let(:params) {{id: "no-exists"}}     
      it "returns a 404" do
        do_request
        expect(response.status).to eq 404
      end
    end

  end
end





require 'rails_helper'

RSpec.describe ShortLinksController, type: :controller do
  let!(:user)         { create :user }
  let!(:bot)          { create :bot, provider: 'facebook' }
  let!(:bot_instance) { create :bot_instance, bot: bot }
  let!(:bot_user)     { create :bot_user, bot_instance: bot_instance}
  let!(:bc1)          { create :bot_collaborator, bot: bot, user: user }
  let!(:url)          { 'http://www.google.com' }

  before do
    sign_in user
  end

  describe 'POST create' do
    def do_request
      post :create, params
    end

    before { ENV['RAILS_HOST'] = "https://www.getbotmetrics.com" }
    after  { ENV['RAILS_HOST'] = nil }

    context 'success' do
      let(:params) { { url: url, user_id: bot_user.uid, bot_id: bot.uid } }

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

      it 'should create an event for "followed-link"' do
        expect {
          do_request
          bot_instance.reload
        }.to change(bot_instance.events,:count).by(1)

        event = bot_instance.events.last

        expect(event.user).to eql bot_user
        expect(event.event_type).to eql 'followed-link'
        expect(event.event_attributes['url']).to eql url
        expect(event.event_attributes['slug']).to_not be_empty
        expect(event.provider).to eql bot.provider
      end

      it "returns 200" do
        do_request
        expect(response.status).to eq 200
      end

      context 'with the SHORTLINK_HOST set' do
        before { ENV['SHORTLINK_HOST'] = 'https://www.bot.af' }
        after  { ENV['SHORTLINK_HOST'] = nil }

        it 'should return the shortlink with the host set as ENV["SHORTLINK_HOST"]' do
          do_request
          short_link = bot_instance.short_links.last

          url_returned = JSON.parse(response.body)['url']
          expect(url_returned).to eql "https://www.bot.af/to/#{short_link.slug}"
        end
      end

      context 'without the SHORTLINK_HOST set' do
        it 'should return the shortlink with the host set as ENV["SHORTLINK_HOST"]' do
          do_request
          short_link = bot_instance.short_links.last

          url_returned = JSON.parse(response.body)['url']
          expect(url_returned).to eql "https://www.getbotmetrics.com/to/#{short_link.slug}"
        end
      end

      context 'for a slack provider' do
        before do
          bot.update_attribute(:provider, 'slack')
        end

        let!(:bi2)        { create :bot_instance, bot: bot, uid: 'TDEADBEEF3' }
        let!(:bot_user2)  { create :bot_user, bot_instance: bi2 }

        context 'without passing team_id' do
          it 'does not create a ShortLink'do
            expect {
              do_request
              bot_instance.reload
            }.to_not change(bot_instance.short_links, :count)
          end

          it 'returns 400' do
            do_request
            expect(response.status).to eq 400
          end
        end

        context 'while passing team_id' do
          let(:params) { { url: url, user_id: bot_user2.uid, bot_id: bot.uid, team_id: bi2.uid } }

          it "returns a shortened link" do
            expect {
              do_request
              bi2.reload
            }.to change(bi2.short_links,:count).by(1)

            short_link = bi2.short_links.last
            expect(short_link.bot_user).to eql bot_user2
            expect(short_link.url).to eql url
            expect(short_link.slug).to_not be_empty
          end

          it 'should create an event for "followed-link"' do
            expect {
              do_request
              bi2.reload
            }.to change(bi2.events, :count).by(1)

            event = bi2.events.last

            expect(event.user).to eql bot_user2
            expect(event.event_type).to eql 'followed-link'
            expect(event.event_attributes['url']).to eql url
            expect(event.event_attributes['slug']).to_not be_empty
            expect(event.provider).to eql bot.provider
          end

          it "returns 200" do
            do_request
            expect(response.status).to eq 200
          end
        end
      end
    end

    context 'failure' do
      context 'missing url' do
        let(:params) { { url: '', bot_user_id: bot_user.uid, bot_id: bot.uid } }

        it 'does not create a ShortLink'do
          expect {
            do_request
            bot_instance.reload
          }.to_not change(bot_instance.short_links, :count)
        end

        it 'returns 400' do
          do_request
          expect(response.status).to eq 400
        end
      end
    end
  end

  describe 'GET show' do
    let!(:short_link)     { create :short_link }

    def do_request(id)
      get :show, id: id
    end

    context "slug exists" do
      it "redirects to URL" do
        do_request(short_link.to_param)
        expect(response).to redirect_to(short_link.url)
      end
    end

    context "slug doesn't exist" do
      it "returns a 404" do
        do_request("doesnt exist")
        expect(response.status).to eq 404
      end
    end
  end
end

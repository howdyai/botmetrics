require 'rails_helper'

RSpec.describe SubscribeUserToUpdatesJob do
  describe '#perform' do
    let!(:email) { Faker::Internet.email }
    let!(:name)  { Faker::Name.name }
    let!(:user)  { create :user, email: email, full_name: name }

    before do
      params = {
        install: {
          email: email,
          full_name: name
        }
      }
      stub_request(:post, "https://phonehome.getbotmetrics.com/installs").
              with(body: params.to_query,
                   headers: {'Content-Type'=>'application/x-www-form-urlencoded', 'Host'=>'phonehome.getbotmetrics.com'}).
               to_return(status: 201)
    end

    it 'subscribes the user to updates and security patches' do
      status = SubscribeUserToUpdatesJob.new.perform(user.id)
      expect(status).to eql 201
    end
  end
end

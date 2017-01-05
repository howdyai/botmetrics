require 'rails_helper'

RSpec.describe SendHeartbeatJob do
  describe '#perform' do
    let!(:email) { Faker::Internet.email }
    let!(:name)  { Faker::Name.name }
    let!(:user)  { create :user, email: email, full_name: name }

    before do
      params = {
        install: {
          email: email,
          full_name: name,
          events: 0,
          users: 0
        }
      }
      stub_request(:post, "https://phonehome.getbotmetrics.com/installs/heartbeat").
              with(body: params.to_query,
                   headers: {'Content-Type'=>'application/x-www-form-urlencoded', 'Host'=>'phonehome.getbotmetrics.com'}).
               to_return(status: 200)
    end

    it 'should send heartbeat' do
      status = SendHeartbeatJob.new.perform
      expect(status).to eql 200
    end
  end
end

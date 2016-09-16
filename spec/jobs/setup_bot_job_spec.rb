RSpec.describe SetupBotJob do
  let(:slack_api)     { ENV['SLACK_API_URL'] }
  let(:facebook_api)  { ENV['FACEBOOK_API_URL'] }
  let(:kik_api)       { ENV['KIK_API_URL'] }

  let!(:user) { create :user }

  describe '#perform' do
    context 'slack' do
      let!(:bi)   { create :bot_instance, token: 'token' }

      before do
        allow_any_instance_of(Object).to receive(:sleep)
        bi.update_attribute(:provider, 'slack')
      end

      context 'when token is valid' do
        let!(:auth_test_response) do
          { ok: true, url: "https://myteam.slack.com/", team: "My Team", user: "cal", team_id: "T12345", user_id: "U12345"}.to_json
        end

        let!(:users_list_response) do
          {
            "ok" => true,
            "members" => [
              {
                'id' => 'UDEADBEEF1',
                'name' => 'sjobs',
                'tz' => 'Los Angeles',
                'tz_label' => 'Pacific Daylight Time',
                'tz_offset' => '-25200',
                'profile' => {
                  'email' => 'sjobs@apple.com',
                  'first_name' => 'Steve',
                  'last_name' => 'Jobs',
                  'real_name' => 'Steve Jobs',
                },
                'is_admin' => true,
                'is_owner' => true,
                'is_restricted' => false
              },
              {
                'id' => 'UDEADBEEF2',
                'name' => 'elonmusk',
                'profile' => {
                  'email' => 'elon@apple.com',
                  'first_name' => 'Elon',
                  'last_name' => 'Musk',
                  'real_name' => 'Elon Musk',
                },
                'tz' => 'Los Angeles',
                'tz_label' => 'Pacific Daylight Time',
                'tz_offset' => '-25200',
                'is_admin' => false,
                'is_owner' => false,
                'is_restricted' => true
              },
              {
                'id' => 'UDEADBEEF3',
                'name' => 'timcook',
                'profile' => {
                  'email' => 'tim@apple.com',
                  'first_name' => 'Tim',
                  'last_name' => 'Cook',
                  'real_name' => 'Tim Cook',
                },
                'tz' => 'Los Angeles',
                'tz_label' => 'Pacific Daylight Time',
                'tz_offset' => '-25200',
                'is_admin' => true,
                'is_owner' => false,
                'is_restricted' => false,
                'deleted' => true
              },
            ]
          }.to_json
        end


        before do
          allow(Relax::Bot).to receive(:start!)
          stub_request(:get, "#{slack_api}/auth.test?token=#{bi.token}").
            to_return(status: 200, body: auth_test_response)
          stub_request(:get, "#{slack_api}/users.list?token=#{bi.token}").
            to_return(status: 200, body: users_list_response)

          allow(PusherJob).to receive(:perform_async)
          allow(Alerts::CreatedBotInstanceJob).to receive(:perform_async)
          allow(NotifyAdminOnSlackJob).to receive(:perform_async)
        end

        it 'should enable the bot and setup team_id, team_name and team_url' do
          SetupBotJob.new.perform(bi.id, user.id)
          bi.reload
          expect(bi.state).to eql 'enabled'
          expect(bi.uid).to eql 'U12345'
          expect(bi.instance_attributes['team_id']).to eql 'T12345'
          expect(bi.instance_attributes['team_name']).to eql 'My Team'
          expect(bi.instance_attributes['team_url']).to eql 'https://myteam.slack.com/'
        end

        context 'an existing bot instance exists that is enabled with the same uid and team_id' do
          let!(:existing_bi) { create :bot_instance, bot: bi.bot, uid: 'U12345', state: 'enabled', token: 'old-token', instance_attributes: { team_id: 'T12345', team_name: 'My Team', team_url: 'https://myteam.slack.com' } }

          before do
            stub_request(:get, "#{slack_api}/auth.test?token=#{existing_bi.token}").
              to_return(status: 200, body: auth_test_response)
            stub_request(:get, "#{slack_api}/users.list?token=#{existing_bi.token}").
              to_return(status: 200, body: users_list_response)
          end

          it 'should enable the bot and setup team_id, team_name and team_url' do
            SetupBotJob.new.perform(bi.id, user.id)
            expect(BotInstance.find_by(id: bi.id)).to be_nil

            existing_bi.reload
            expect(existing_bi.state).to eql 'enabled'
            expect(existing_bi.uid).to eql 'U12345'
            expect(existing_bi.token).to eql 'token'
            expect(existing_bi.instance_attributes['team_id']).to eql 'T12345'
            expect(existing_bi.instance_attributes['team_name']).to eql 'My Team'
            expect(existing_bi.instance_attributes['team_url']).to eql 'https://myteam.slack.com/'
          end
        end

        it 'should send a message to Pusher' do
          SetupBotJob.new.perform(bi.id, user.id)
          expect(PusherJob).to have_received(:perform_async).with("setup-bot", "setup-bot-#{bi.id}", "{\"ok\":true}")
        end

        it 'should send an alert' do
          SetupBotJob.new.perform(bi.id, user.id)
          expect(Alerts::CreatedBotInstanceJob).to have_received(:perform_async).with(bi.id, user.id)
        end

        context 'none of the users exist' do
          it 'should add three users' do
            expect {
              SetupBotJob.new.perform(bi.id, user.id)
              bi.reload
            }.to change(bi.users, :count).by(3)

            members = bi.users.order("id ASC")

            user1 = members[0]

            expect(user1.user_attributes['timezone']).to eql 'Los Angeles'
            expect(user1.user_attributes['timezone_description']).to eql 'Pacific Daylight Time'
            expect(user1.user_attributes['timezone_offset']).to eql -25200
            expect(user1.user_attributes['nickname']).to eql 'sjobs'
            expect(user1.user_attributes['email']).to eql 'sjobs@apple.com'
            expect(user1.user_attributes['first_name']).to eql 'Steve'
            expect(user1.user_attributes['last_name']).to eql 'Jobs'
            expect(user1.user_attributes['full_name']).to eql 'Steve Jobs'
            expect(user1.membership_type).to eql 'owner'
            expect(user1.uid).to eql 'UDEADBEEF1'

            user2 = members[1]

            expect(user2.user_attributes['timezone']).to eql 'Los Angeles'
            expect(user2.user_attributes['timezone_description']).to eql 'Pacific Daylight Time'
            expect(user2.user_attributes['timezone_offset']).to eql -25200
            expect(user2.user_attributes['nickname']).to eql 'elonmusk'
            expect(user2.user_attributes['email']).to eql 'elon@apple.com'
            expect(user2.user_attributes['first_name']).to eql 'Elon'
            expect(user2.user_attributes['last_name']).to eql 'Musk'
            expect(user2.user_attributes['full_name']).to eql 'Elon Musk'
            expect(user2.membership_type).to eql 'guest'
            expect(user2.uid).to eql 'UDEADBEEF2'

            user3 = members[2]

            expect(user3.user_attributes['timezone']).to eql 'Los Angeles'
            expect(user3.user_attributes['timezone_description']).to eql 'Pacific Daylight Time'
            expect(user3.user_attributes['timezone_offset']).to eql -25200
            expect(user3.user_attributes['nickname']).to eql 'timcook'
            expect(user3.user_attributes['email']).to eql 'tim@apple.com'
            expect(user3.user_attributes['first_name']).to eql 'Tim'
            expect(user3.user_attributes['last_name']).to eql 'Cook'
            expect(user3.user_attributes['full_name']).to eql 'Tim Cook'
            expect(user3.membership_type).to eql 'deleted'
            expect(user3.uid).to eql 'UDEADBEEF3'
          end
        end

        context 'some of the users exist' do
          let!(:existing_user) { create :bot_user, bot_instance: bi, uid: 'UDEADBEEF2', user_attributes: { email: 'elonmusk@apple.com' }, membership_type: 'member' }

          it 'should only add the new users and update info on existing users' do
            expect {
              SetupBotJob.new.perform(bi.id, user.id)
              bi.reload
            }.to change(bi.users, :count).by(2)

            members = bi.users.order("id ASC")

            user1 = members[0]
            expect(user1.user_attributes['timezone']).to eql 'Los Angeles'
            expect(user1.user_attributes['timezone_description']).to eql 'Pacific Daylight Time'
            expect(user1.user_attributes['timezone_offset']).to eql -25200
            expect(user1.user_attributes['nickname']).to eql 'elonmusk'
            expect(user1.user_attributes['email']).to eql 'elon@apple.com'
            expect(user1.user_attributes['first_name']).to eql 'Elon'
            expect(user1.user_attributes['last_name']).to eql 'Musk'
            expect(user1.user_attributes['full_name']).to eql 'Elon Musk'
            expect(user1.membership_type).to eql 'guest'
            expect(user1.uid).to eql 'UDEADBEEF2'

            user2 = members[1]
            expect(user2.user_attributes['timezone']).to eql 'Los Angeles'
            expect(user2.user_attributes['timezone_description']).to eql 'Pacific Daylight Time'
            expect(user2.user_attributes['timezone_offset']).to eql -25200
            expect(user2.user_attributes['nickname']).to eql 'sjobs'
            expect(user2.user_attributes['email']).to eql 'sjobs@apple.com'
            expect(user2.user_attributes['first_name']).to eql 'Steve'
            expect(user2.user_attributes['last_name']).to eql 'Jobs'
            expect(user2.user_attributes['full_name']).to eql 'Steve Jobs'
            expect(user2.membership_type).to eql 'owner'
            expect(user2.uid).to eql 'UDEADBEEF1'

            user3 = members[2]
            expect(user3.user_attributes['timezone']).to eql 'Los Angeles'
            expect(user3.user_attributes['timezone_description']).to eql 'Pacific Daylight Time'
            expect(user3.user_attributes['timezone_offset']).to eql -25200
            expect(user3.user_attributes['nickname']).to eql 'timcook'
            expect(user3.user_attributes['email']).to eql 'tim@apple.com'
            expect(user3.user_attributes['first_name']).to eql 'Tim'
            expect(user3.user_attributes['last_name']).to eql 'Cook'
            expect(user3.user_attributes['full_name']).to eql 'Tim Cook'
            expect(user3.membership_type).to eql 'deleted'
            expect(user3.uid).to eql 'UDEADBEEF3'
          end
        end

        it 'should call Relax::Bot.start' do
          SetupBotJob.new.perform(bi.id, user.id)
          expect(Relax::Bot).to have_received(:start!).with('T12345', 'token', namespace: 'U12345')
        end
      end

      context 'when token is invalid' do
        before do
          stub_request(:get, "#{slack_api}/auth.test?token=#{bi.token}").
                    to_return(status: 200, body: { ok: false, error: "invalid_token" }.to_json)
          allow(PusherJob).to receive(:perform_async)
        end

        it 'should keep the bot in pending state' do
          SetupBotJob.new.perform(bi.id, user.id)
          bi.reload
          expect(bi.state).to eql 'pending'
          expect(bi.uid).to be_nil
          expect(bi.instance_attributes).to eql({})
        end

        it 'should send a message to Pusher' do
          SetupBotJob.new.perform(bi.id, user.id)
          expect(PusherJob).to have_received(:perform_async).with("setup-bot", "setup-bot-#{bi.id}", "{\"ok\":false,\"error\":\"invalid_token\"}")
        end
      end

      context 'when token is for a disabled bot' do
        before do
          stub_request(:get, "#{slack_api}/auth.test?token=#{bi.token}").
                    to_return(status: 200, body: { ok: false, error: "account_inactive" }.to_json)
          allow(PusherJob).to receive(:perform_async)
        end

        it 'should disable the bot' do
          SetupBotJob.new.perform(bi.id, user.id)
          bi.reload
          expect(bi.state).to eql 'disabled'
          expect(bi.uid).to be_nil
          expect(bi.instance_attributes).to eql({})
        end

        it 'should create a "bot_disabled" event' do
          expect {
            SetupBotJob.new.perform(bi.id, user.id)
            bi.reload
          }.to change(bi.events, :count).by(1)

          event = bi.events.last
          expect(event.event_type).to eql 'bot_disabled'
          expect(event.provider).to eql 'slack'
        end

        it 'should send a message to Pusher' do
          SetupBotJob.new.perform(bi.id, user.id)
          expect(PusherJob).to have_received(:perform_async).with("setup-bot", "setup-bot-#{bi.id}", "{\"ok\":false,\"error\":\"account_inactive\"}")
        end
      end
    end

    context 'facebook' do
      let!(:bi_facebook)   { create :bot_instance, :with_attributes_facebook, token: 'token', provider: 'facebook' }

      before do
        allow_any_instance_of(Object).to receive(:sleep)
      end

      context 'when token is valid' do
        let!(:auth_test_response) do
          { name: "My Team", id: "T12345", status: 200 }.to_json
        end

        before do
          stub_request(:get, "#{facebook_api}/me?access_token=#{bi_facebook.token}").
            to_return(status: 200, body: auth_test_response)

          allow(PusherJob).to receive(:perform_async)
          allow(NotifyAdminOnSlackJob).to receive(:perform_async)
        end

        it 'should enable the bot and setup name' do
          SetupBotJob.new.perform(bi_facebook.id, user.id)
          bi_facebook.reload
          expect(bi_facebook.state).to eql 'enabled'
          expect(bi_facebook.uid).to eql 'T12345'
          expect(bi_facebook.instance_attributes['name']).to eql 'My Team'
        end

        it 'should send a message to Pusher' do
          SetupBotJob.new.perform(bi_facebook.id, user.id)
          expect(PusherJob).to have_received(:perform_async).with("setup-bot", "setup-bot-#{bi_facebook.id}", "{\"ok\":true}")
        end
      end

      context 'when token is invalid' do
        before do
          stub_request(:get, "#{facebook_api}/me?access_token=#{bi_facebook.token}").
                    to_return(status: 400, body: { error: { message: 'Invalid OAuth access token.' } }.to_json)
          allow(PusherJob).to receive(:perform_async)
        end

        it 'should keep the bot in disabled state' do
          SetupBotJob.new.perform(bi_facebook.id, user.id)
          bi_facebook.reload
          expect(bi_facebook.state).to eql 'disabled'
          expect(bi_facebook.uid).to be_nil
          expect(bi_facebook.instance_attributes).to eql({ 'name' => 'N123' })
        end

        it 'should send a message to Pusher' do
          SetupBotJob.new.perform(bi_facebook.id, user.id)
          expect(PusherJob).to have_received(:perform_async).with("setup-bot", "setup-bot-#{bi_facebook.id}", "{\"ok\":false,\"error\":\"Invalid OAuth access token.\"}")
        end
      end

      context 'when token is for a disabled bot' do
        let!(:bi_facebook_with_attrs)   { create :bot_instance, :with_attributes_facebook, provider: 'facebook' }

        before do
          stub_request(:get, "#{facebook_api}/me?access_token=#{bi_facebook_with_attrs.token}").
                    to_return(status: 400, body: { ok: false, error: {
                                                   message: 'This Page access token belongs to a Page that has been deleted.',
                                                 } }.to_json)
          allow(PusherJob).to receive(:perform_async)
        end

        it 'should disable the bot' do
          SetupBotJob.new.perform(bi_facebook_with_attrs.id, user.id)
          bi_facebook_with_attrs.reload
          expect(bi_facebook_with_attrs.state).to eql 'disabled'
          expect(bi_facebook_with_attrs.uid).to be_nil
          expect(bi_facebook_with_attrs.instance_attributes).to eql({ 'name' => 'N123' })
        end

        it 'should send a message to Pusher' do
          SetupBotJob.new.perform(bi_facebook_with_attrs.id, user.id)
          expect(PusherJob).to have_received(:perform_async).with("setup-bot", "setup-bot-#{bi_facebook_with_attrs.id}", "{\"ok\":false,\"error\":\"This Page access token belongs to a Page that has been deleted.\"}")
        end
      end
    end

    context 'kik' do
      let!(:bi_kik)    { create :bot_instance, :with_attributes_kik, token: 'token', provider: 'kik' }
      let(:auth_token) { Base64.encode64("#{bi_kik.uid}:#{bi_kik.token}").chop }

      before do
        allow_any_instance_of(Object).to receive(:sleep)
      end

      context 'when token is valid' do
        let!(:auth_test_response) do
          {
            'webhook' => 'webhook',
            'features' => {
              'receiveReadReceipts' => false,
              'receiveIsTyping' => false,
              'manuallySendReadReceipts' => false,
              'receiveDeliveryReceipts' => false
            }
          }
        end

        before do
          stub_request(:get, "#{kik_api}/config").
            with(:headers => {'Authorization'=>"Basic #{auth_token}", 'Host'=>'api.kik.com'}).
            to_return(status: 200, body: auth_test_response.to_json)

          allow(PusherJob).to receive(:perform_async)
          allow(Alerts::CreatedBotInstanceJob).to receive(:perform_async)
          allow(NotifyAdminOnSlackJob).to receive(:perform_async)
        end

        it 'should enable the bot and setup name' do
          SetupBotJob.new.perform(bi_kik.id, user.id)
          bi_kik.reload
          expect(bi_kik.state).to eql 'enabled'
          expect(bi_kik.uid).to eql 'U12345'
          expect(bi_kik.instance_attributes).to eql auth_test_response
        end

        it 'should send a message to Pusher' do
          SetupBotJob.new.perform(bi_kik.id, user.id)
          expect(PusherJob).to have_received(:perform_async).with("setup-bot", "setup-bot-#{bi_kik.id}", "{\"ok\":true}")
        end

        it 'should send an alert' do
          SetupBotJob.new.perform(bi_kik.id, user.id)
          expect(Alerts::CreatedBotInstanceJob).to have_received(:perform_async).with(bi_kik.id, user.id)
        end
      end

      context 'when token is invalid' do
        before do
          stub_request(:get, "#{kik_api}/config").
                    to_return(status: 400, body: { error: 'Invalid OAuth access token.' }.to_json)
          allow(PusherJob).to receive(:perform_async)
        end

        it 'should keep the bot in disabled state' do
          SetupBotJob.new.perform(bi_kik.id, user.id)
          bi_kik.reload
          expect(bi_kik.state).to eql 'disabled'
          expect(bi_kik.uid).to be_nil
          expect(bi_kik.instance_attributes).to be_present
        end

        it 'should send a message to Pusher' do
          SetupBotJob.new.perform(bi_kik.id, user.id)
          expect(PusherJob).to have_received(:perform_async).with("setup-bot", "setup-bot-#{bi_kik.id}", "{\"ok\":false,\"error\":\"Invalid OAuth access token.\"}")
        end
      end
    end
  end
end

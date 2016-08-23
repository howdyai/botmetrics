RSpec.describe FacebookEventsService do
  let!(:timestamp)    { Time.now.to_i * 1000 }
  let!(:admin_user)   { create :user }
  let!(:bot)          { create :bot, provider: 'facebook' }
  let!(:bc1)          { create :bot_collaborator, bot: bot, user: admin_user }
  let!(:bot_instance) { create :bot_instance, provider: 'facebook', bot: bot }
  let!(:first_name)  { Faker::Name.first_name }
  let!(:last_name)   { Faker::Name.last_name  }
  let!(:profile_pic) { Faker::Avatar.image("my-own-slug") }
  let!(:locale)      { 'en-US' }
  let!(:timezone)    { 3 }
  let!(:gender)      { "female" }
  let!(:fb_client)   { double(Facebook) }

  def do_request
    FacebookEventsService.new(bot_id: bot.uid, events: events).create_events!
  end


  before do
    allow(Facebook).to receive(:new).with(bot_instance.token).and_return(fb_client)
    allow(SetMixpanelPropertyJob).to receive(:perform_async)

    allow(fb_client).to receive(:call).
                     with(fb_user_id, :get, fields: 'first_name,last_name,profile_pic,locale,timezone,gender' ).
                     and_return(first_name: first_name,
                                last_name: last_name,
                                profile_pic: profile_pic,
                                locale: locale,
                                timezone: timezone,
                                gender: gender)
  end

  shared_examples "associates event with custom dashboard if custom dashboards exist" do
    let!(:dashboard1) { create :dashboard, bot: bot, regex: 'hello', dashboard_type: 'custom', provider: 'slack' }
    let!(:dashboard2) { create :dashboard, bot: bot, regex: 'world', dashboard_type: 'custom', provider: 'slack' }
    let!(:dashboard3) { create :dashboard, bot: bot, regex: 'welcome', dashboard_type: 'custom', provider: 'slack' }

    it 'should associate events with dashboards that match the text' do
      do_request
      dashboard1.reload; dashboard2.reload; dashboard3.reload
      e = bot_instance.events.last

      expect(dashboard1.events.to_a).to eql [e]
      expect(dashboard2.events.to_a).to eql [e]
      expect(dashboard3.events.to_a).to be_empty
    end
  end

  shared_examples "should create an event as well as create the bot users" do
    it "should create an event" do
      expect {
        do_request
        bot_instance.reload
      }.to change(bot_instance.events, :count).by(1)

      event = bot_instance.events.last

      expect(event.event_type).to eql event_type
      expect(event.provider).to eql 'facebook'
      expect(event.user).to eql BotUser.find_by(uid: fb_user_id)
      expect(event.event_attributes.slice(*required_event_attributes.keys)).to eql required_event_attributes
      expect(event.text).to eql text
      expect(event.created_at.to_i).to eql timestamp / 1000
      expect(event.is_from_bot).to be is_from_bot
      expect(event.is_im).to be is_im
      expect(event.is_for_bot).to be is_for_bot
    end

    it "should create a new BotUser" do
      expect {
        do_request
        bot_instance.reload
      }.to change(bot_instance.users, :count).by(1)

      user = bot_instance.users.last
      expect(user.user_attributes['first_name']).to eql first_name
      expect(user.user_attributes['last_name']).to eql last_name
      expect(user.user_attributes['profile_pic']).to eql profile_pic
      expect(user.user_attributes['locale']).to eql locale
      expect(user.user_attributes['timezone']).to eql timezone
      expect(user.user_attributes['gender']).to eql gender
      expect(user.uid).to eql fb_user_id
      expect(user.provider).to eql 'facebook'
      expect(user.membership_type).to eql 'user'
    end


    it 'should increment bot_interaction_count if is_for_bot, otherwise do not increment' do
      do_request
      user = bot_instance.users.last

      if is_for_bot
        expect(user.bot_interaction_count).to eql 1
      else
        expect(user.bot_interaction_count).to eql 0
      end
    end

    it "should set last_interacted_with_bot_at to the event's created_at timestamp if is_for_bot, otherwise don't do anything" do
      do_request
      user = bot_instance.users.last
      event = bot_instance.events.last

      if is_for_bot
        expect(user.last_interacted_with_bot_at).to eql event.created_at
      else
        expect(user.last_interacted_with_bot_at).to be_nil
      end
    end
  end

  shared_examples "should create an event but not create any bot users" do
    let!(:user)        { create :bot_user, provider: 'facebook', bot_instance: bot_instance, uid: fb_user_id }

    it "should create an event" do
      expect {
        do_request
        bot_instance.reload
      }.to change(bot_instance.events, :count).by(1)

      event = bot_instance.events.last

      expect(event.event_type).to eql event_type
      expect(event.provider).to eql 'facebook'
      expect(event.user).to eql user
      expect(event.event_attributes.slice(*required_event_attributes.keys)).to eql required_event_attributes
      expect(event.text).to eql text
      expect(event.created_at.to_i).to eql timestamp / 1000
      expect(event.is_from_bot).to be is_from_bot
      expect(event.is_im).to be is_im
      expect(event.is_for_bot).to be is_for_bot
    end

    it "should NOT create new BotUsers" do
      expect {
        do_request
        bot_instance.reload
      }.to_not change(bot_instance.users, :count)

      expect(fb_client).to_not have_received(:call)
    end

    it 'should increment bot_interaction_count if is_for_bot, otherwise do not increment' do
      if is_for_bot
        expect {
          do_request
          user.reload
        }.to change(user, :bot_interaction_count).from(0).to(1)
      else
        expect {
          do_request
          user.reload
        }.to_not change(user, :bot_interaction_count)
      end
    end

    it "should set last_interacted_with_bot_at to the event's created_at timestamp if is_for_bot, otherwise don't do anything" do
      if is_for_bot
        expect {
          do_request
          user.reload
        }.to change(user, :last_interacted_with_bot_at)

        expect(user.last_interacted_with_bot_at).to eql bot_instance.events.last.created_at
      else
        expect {
          do_request
          user.reload
        }.to_not change(user, :last_interacted_with_bot_at)
      end
    end
  end

  shared_examples "sets the mixpanel property 'received_first_event' if first_received_event_at is nil" do
    context "first_received_event_at is not nil" do
      it 'should update first_received_event_at and set the property on Mixpanel' do
        expect {
          do_request
          bot.reload
        }.to change(bot, :first_received_event_at)
      end

      it 'should set the mixpanel property "received_first_event" to true' do
        do_request
        expect(SetMixpanelPropertyJob).to have_received(:perform_async).with(admin_user.id, 'received_first_event', true)
      end
    end

    context "first_received_event_at is NOT nil" do
      before { bot.update_attribute(:first_received_event_at, Time.now) }

      it 'should NOT update first_received_event_at and set the property on Mixpanel' do
        expect {
          do_request
          bot.reload
        }.to_not change(bot, :first_received_event_at)
      end

      it 'should NOT set the mixpanel property "received_first_event" to true' do
        do_request
        expect(SetMixpanelPropertyJob).to_not have_received(:perform_async).with(admin_user.id, 'received_first_event', true)
      end
    end
  end

  describe '"messages" events' do
    let(:fb_user_id)    { "fb-user-id"  }
    let(:bot_user_id)   { bot.uid       }
    let(:mid)           { "mid-1"       }
    let(:seq)           { 8888          }
    let(:text)          { "hello-world" }
    let(:event_type)    { 'message'     }
    let(:is_from_bot)   { false }
    let(:is_for_bot)    { true  }
    let(:is_im)         { true  }
    let(:required_event_attributes) {
      Hash["mid", "mid-1", "seq", 8888]
    }

    let(:events) do
      {
        "entry": [{
          "id": "268855423495782",
          "time": 1470403317713,
          "messaging": [{
            "sender":{
              "id": fb_user_id
            },
            "recipient":{
              "id": bot_user_id
            },
            "timestamp": timestamp,
            "message":{
              "mid": required_event_attributes['mid'],
              "seq": required_event_attributes['seq'],
              "text": text,
              "quick_reply": {
                "payload": "DEVELOPER_DEFINED_PAYLOAD"
              }
            }
          }]
        }]
      }
    end

    context "bot user exists" do
      it_behaves_like "should create an event as well as create the bot users"
      it_behaves_like "associates event with custom dashboard if custom dashboards exist"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"

      it "should succeed if the same call is called more than once" do
        expect {
          do_request
          do_request
          bot_instance.reload
        }.to change(bot_instance.events, :count).by(1)
      end
    end

    context "bot user does not exist" do
      it_behaves_like "should create an event but not create any bot users"
      it_behaves_like "associates event with custom dashboard if custom dashboards exist"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"

      it "should succeed if the same call is called more than once" do
        expect {
          do_request
          do_request
          bot_instance.reload
        }.to change(bot_instance.events, :count).by(1)
      end
    end
  end

  describe '"message_echoes" event' do
    let(:fb_user_id)    { "fb-user-id"  }
    let(:bot_user_id)   { bot.uid       }
    let(:text)          { "hello-world" }
    let(:event_type)    { 'message'     }
    let(:is_from_bot)   { true          }
    let(:is_for_bot)    { false         }
    let(:is_im)         { true          }
    let(:required_event_attributes) {
      Hash["mid", "mid-1", "seq", "seq-1"]
    }

    let(:events) do
      {
        entry: [{
          id: "268855423495782",
          time: 1470403317713,
          messaging: [{
            sender:{
              id: bot_user_id
            },
            recipient:{
              id: fb_user_id
            },
            timestamp: timestamp,
            message: {
              is_echo: true,
              mid: required_event_attributes['mid'],
              seq: required_event_attributes['seq'],
              text: text,
              quick_reply: {
                payload: "DEVELOPER_DEFINED_PAYLOAD"
              }
            }
          }]
        }]
      }
    end

    context "bot user exists" do
      it_behaves_like "should create an event as well as create the bot users"
      it_behaves_like "associates event with custom dashboard if custom dashboards exist"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"

      it "should succeed if the same call is called more than once" do
        expect {
          do_request
          do_request
          bot_instance.reload
        }.to change(bot_instance.events, :count).by(1)
      end
    end

    context "bot user does not exist" do
      it_behaves_like "should create an event but not create any bot users"
      it_behaves_like "associates event with custom dashboard if custom dashboards exist"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"

      it "should succeed if the same call is called more than once" do
        expect {
          do_request
          do_request
          bot_instance.reload
        }.to change(bot_instance.events, :count).by(1)
      end
    end
  end

  describe '"message_reads" event' do
    let(:fb_user_id)    { "fb-user-id"  }
    let(:bot_user_id)   { bot.uid       }
    let!(:user)         { create :bot_user, bot_instance: bot_instance, provider: 'facebook' }
    let!(:e1)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'facebook',
                     event_attributes: { mid: "mid-1", seq: "seq-1" },
                     created_at: 2.days.ago
    end
    let!(:e2)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'facebook',
                     event_attributes: { mid: "mid-1", seq: "seq-2" },
                     created_at: 2.days.ago
    end
    let!(:e3)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'facebook',
                     event_attributes: { mid: "mid-1", seq: "seq-3" },
                     created_at: Time.at(timestamp / 1000 + 2.days)
    end
    let!(:e4)    do
      create :event, user: user, event_type: 'message', provider: 'facebook',
                     event_attributes: { mid: "mid-1", seq: "seq-4" },
                     created_at: 3.days.ago
    end

    let(:events) do
      {
        entry: [{
          id: "268855423495782",
          time: 1470403317713,
          messaging: [{
            sender:{
              id: fb_user_id
            },
            recipient:{
              id: bot_user_id
            },
            timestamp: timestamp,
            read: {
              watermark: timestamp,
              seq: 38
            }
          }]
        }]
      }
    end

    it "should update the 'has_been_read' value for all of the events that belong to the bot_instance to 'true'" do
      do_request
      expect(e1.reload.has_been_read).to be true
      expect(e2.reload.has_been_read).to be true
      expect(e3.reload.has_been_read).to be false
      expect(e4.reload.has_been_read).to be false
    end
  end

  describe '"message_deliveries" event' do
    let(:fb_user_id)    { "fb-user-id"  }
    let(:bot_user_id)   { bot.uid       }
    let!(:user)  { create :bot_user, bot_instance: bot_instance, provider: 'facebook' }
    let!(:e1)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'facebook',
                     event_attributes: { mid: "mid-1", seq: "seq-1" },
                     created_at: 2.days.ago
    end
    let!(:e2)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'facebook',
                     event_attributes: { mid: "mid-1", seq: "seq-2" },
                     created_at: 2.days.ago
    end
    let!(:e3)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'facebook',
                     event_attributes: { mid: "mid-1", seq: "seq-3" },
                     created_at: Time.at(timestamp / 1000 + 2.days)
    end
    let!(:e4)    do
      create :event, user: user, event_type: 'message', provider: 'facebook',
                     event_attributes: { mid: "mid-1", seq: "seq-4" },
                     created_at: 3.days.ago
    end

    let(:events) do
      {
        entry: [{
          id: "268855423495782",
          time: 1470403317713,
          messaging: [{
            sender:{
              id: fb_user_id
            },
            recipient:{
              id: bot_user_id
            },
            timestamp: timestamp,
            delivery: {
              mids:[
                "mid.1458668856218:ed81099e15d3f4f233"
              ],
              watermark: timestamp,
              seq: 38
            }
          }]
        }]
      }
    end

    it "should update the 'has_been_delivered' value for all of the events that belong to the bot_instance to 'true'" do
      do_request
      expect(e1.reload.has_been_delivered).to be true
      expect(e2.reload.has_been_delivered).to be true
      expect(e3.reload.has_been_delivered).to be false
      expect(e4.reload.has_been_delivered).to be false
    end
  end

  describe '"messaging_optins" event' do
    let(:fb_user_id)    { "fb-user-id"       }
    let(:bot_user_id)   { bot.uid            }
    let(:text)          { nil                }
    let(:event_type)    { 'messaging_optins' }
    let(:is_from_bot)   { false }
    let(:is_for_bot)    { true  }
    let(:is_im)         { true  }
    let(:required_event_attributes) {
      Hash["optin"=> { "ref"=> "PASS_THROUGH_PARAM" }]
    }

    let(:events) do
      {
        "entry": [{
          "id": "268855423495782",
          "time": 1470403317713,
          "messaging": [{
            "sender":{
              "id": fb_user_id
            },
            "recipient":{
              "id": bot_user_id
            },
            "timestamp": timestamp,
            "optin":{
              "ref": "PASS_THROUGH_PARAM"
            }
          }]
        }]
      }
    end

    context "bot user exists" do
      it_behaves_like "should create an event as well as create the bot users"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"
    end

    context "bot user does not exist" do
      it_behaves_like "should create an event but not create any bot users"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"
    end
  end

  describe '"messaging_postbacks" event' do
    let(:fb_user_id)    { "fb-user-id"          }
    let(:bot_user_id)   { bot.uid               }
    let(:text)          { nil                   }
    let(:event_type)    { 'messaging_postbacks' }
    let(:is_from_bot)   { false }
    let(:is_for_bot)    { true  }
    let(:is_im)         { true  }
    let(:required_event_attributes) {
      Hash["payload", "USER_DEFINED_PAYLOAD"]
    }

    let(:events) do
      {
        "entry": [{
          "id": "268855423495782",
          "time": 1470403317713,
          "messaging": [{
            "sender":{
              "id": fb_user_id
            },
            "recipient":{
              "id": bot_user_id
            },
            "timestamp": timestamp,
            "postback":{
              "payload": "USER_DEFINED_PAYLOAD"
            }
          }]
        }]
      }
    end

    context "bot user exists" do
      it_behaves_like "should create an event as well as create the bot users"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"
    end

    context "bot user does not exist" do
      it_behaves_like "should create an event but not create any bot users"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"
    end
  end

  describe '"account_linking" event' do
    let(:fb_user_id)    { "fb-user-id"      }
    let(:bot_user_id)   { bot.uid           }
    let(:text)          { nil               }
    let(:event_type)    { 'account_linking' }
    let(:is_from_bot)   { false }
    let(:is_for_bot)    { true  }
    let(:is_im)         { true  }
    let(:required_event_attributes) {
      Hash["account_linking"=> { "status"=> "linked", "authorization_code"=> "PASS_THROUGH_AUTHORIZATION_CODE" }]
    }

    let(:events) do
      {
        "entry": [{
          "id": "268855423495782",
          "time": 1470403317713,
          "messaging": [{
            "sender":{
              "id": fb_user_id
            },
            "recipient":{
              "id": bot_user_id
            },
            "timestamp": timestamp,
            "account_linking":{
              "status": "linked",
              "authorization_code": "PASS_THROUGH_AUTHORIZATION_CODE"
            }
          }]
        }]
      }
    end

    context "bot user exists" do
      it_behaves_like "should create an event as well as create the bot users"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"
    end

    context "bot user does not exist" do
      it_behaves_like "should create an event but not create any bot users"
      it_behaves_like "sets the mixpanel property 'received_first_event' if first_received_event_at is nil"
    end
  end
end

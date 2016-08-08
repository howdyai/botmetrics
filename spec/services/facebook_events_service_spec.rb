RSpec.describe FacebookEventsService do
  let!(:timestamp)    { Time.now.to_i * 1000 }
  let!(:bot)          { create :bot, provider: 'facebook' }
  let!(:bot_instance) { create :bot_instance, provider: 'facebook', bot: bot }

  subject { FacebookEventsService.new(bot_id: bot.uid, events: events).create_events! }

  shared_examples "should create an event as well as create the bot users" do
    let!(:fb_client)   { double(Facebook) }
    let!(:first_name)  { Faker::Name.first_name }
    let!(:last_name)   { Faker::Name.last_name  }
    let!(:profile_pic) { Faker::Avatar.image("my-own-slug") }
    let!(:locale)      { 'en-US' }
    let!(:timezone)    { 3 }
    let!(:gender)      { "female" }

    before do
      allow(Facebook).to receive(:new).with(bot_instance.token).and_return(fb_client)

      allow(fb_client).to receive(:call).
                       with(fb_user_id, :get, fields: 'first_name,last_name,profile_pic,locale,timezone,gender' ).
                       and_return(first_name: first_name,
                                  last_name: last_name,
                                  profile_pic: profile_pic,
                                  locale: locale,
                                  timezone: timezone,
                                  gender: gender)
    end

    it "should create an event" do
      expect {
        subject
        bot_instance.reload
      }.to change(bot_instance.events, :count).by(1)

      event = bot_instance.events.last

      expect(event.event_type).to eql 'message'
      expect(event.provider).to eql 'facebook'
      expect(event.user).to eql BotUser.find_by(uid: fb_user_id)
      expect(event.event_attributes['mid']).to eql mid
      expect(event.event_attributes['seq']).to eql seq
      expect(event.text).to eql text
      expect(event.created_at.to_i).to eql timestamp / 1000
      expect(event.is_from_bot).to be is_from_bot
      expect(event.is_im).to be is_im
      expect(event.is_for_bot).to be is_for_bot
    end

    it "should create a new BotUser" do
      expect {
        subject
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
  end

  shared_examples "should create an event but not create any bot users" do
    let!(:user)        { create :bot_user, provider: 'facebook', bot_instance: bot_instance, uid: fb_user_id }

    it "should create an event" do
      expect {
        subject
        bot_instance.reload
      }.to change(bot_instance.events, :count).by(1)

      event = bot_instance.events.last

      expect(event.event_type).to eql event_type
      expect(event.provider).to eql 'facebook'
      expect(event.user).to eql user
      expect(event.event_attributes['mid']).to eql mid
      expect(event.event_attributes['seq']).to eql seq
      expect(event.text).to eql text
      expect(event.created_at.to_i).to eql timestamp / 1000
      expect(event.is_from_bot).to be is_from_bot
      expect(event.is_im).to be is_im
      expect(event.is_for_bot).to be is_for_bot
    end

    it "should NOT create new BotUsers" do
      expect {
        subject
        bot_instance.reload
      }.to_not change(bot_instance.users, :count)
    end
  end

  describe '"messages" events' do
    let(:fb_user_id)    { "fb-user-id"  }
    let(:bot_user_id)   { bot.uid       }
    let(:mid)           { "mid-1"       }
    let(:seq)           { "seq-1"       }
    let(:text)          { "hello-world" }
    let(:event_type)    { 'message'     }
    let(:is_from_bot)   { false }
    let(:is_for_bot)    { true  }
    let(:is_im)         { true  }

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
              "mid": mid,
              "seq": seq,
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
    end

    context "bot user does not exist" do
      it_behaves_like "should create an event but not create any bot users"
    end
  end

  describe '"message_echoes" event' do
    let(:fb_user_id)    { "fb-user-id"  }
    let(:bot_user_id)   { bot.uid       }
    let(:mid)           { "mid-1"       }
    let(:seq)           { "seq-1"       }
    let(:text)          { "hello-world" }
    let(:event_type)    { 'message'     }
    let(:is_from_bot)   { true          }
    let(:is_for_bot)    { false         }
    let(:is_im)         { true          }

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
            message: {
              is_echo: true,
              mid: mid,
              seq: seq,
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
    end

    context "bot user does not exist" do
      it_behaves_like "should create an event but not create any bot users"
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
      subject
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
      subject
      expect(e1.reload.has_been_delivered).to be true
      expect(e2.reload.has_been_delivered).to be true
      expect(e3.reload.has_been_delivered).to be false
      expect(e4.reload.has_been_delivered).to be false
    end
  end
end

RSpec.describe KikEventsService do
  let!(:timestamp)    { Time.now.to_i * 1000 }
  let!(:bot)          { create :bot, provider: 'kik' }
  let!(:bot_instance) { create :bot_instance, provider: 'kik', bot: bot }

  subject { KikEventsService.new(bot_id: bot.uid, events: events).create_events! }

  shared_examples "should create an event as well as create the bot users" do
    let!(:kik_client)   { double(Kik) }
    let!(:first_name)   { Faker::Name.first_name }
    let!(:last_name)   { Faker::Name.last_name }
    let!(:profile_pic_url)           { Faker::Internet.url }
    let!(:profile_pic_last_modified) { Faker::Date.between(2.days.ago, Date.today)  }

    before do
      allow(Kik).to receive(:new).with(bot_instance.token, bot_instance.uid).and_return(kik_client)

      allow(kik_client).to receive(:call).
                       with("user/#{kik_user_id}", :get).
                       and_return(firstName: first_name,
                                  lastName: last_name,
                                  profilePicUrl: profile_pic_url,
                                  profilePicLastModified: profile_pic_last_modified)
    end

    it "should create an event" do
      expect {
        subject
        bot_instance.reload
      }.to change(bot_instance.events, :count).by(1)

      event = bot_instance.events.last

      expect(event.event_type).to eql 'message'
      expect(event.provider).to eql 'kik'
      expect(event.user).to eql BotUser.find_by(uid: kik_user_id)
      expect(event.event_attributes.slice(*required_event_attributes.keys)).to eql required_event_attributes
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
      expect(user.user_attributes['profile_pic_url']).to eql profile_pic_url
      expect(user.user_attributes['profile_pic_last_modified']).to eql profile_pic_last_modified.to_s
      expect(user.uid).to eql kik_user_id
      expect(user.provider).to eql 'kik'
      expect(user.membership_type).to eql 'user'
    end

    it 'should increment bot_interaction_count if is_for_bot, otherwise do not increment' do
      subject
      user = bot_instance.users.last

      if is_for_bot
        expect(user.bot_interaction_count).to eql 1
      else
        expect(user.bot_interaction_count).to eql 0
      end
    end

    it "should set last_interacted_with_bot_at to the event's created_at timestamp if is_for_bot, otherwise don't do anything" do
      subject
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
    let!(:user)        { create :bot_user, provider: 'kik', bot_instance: bot_instance, uid: kik_user_id }

    it "should create an event" do
      expect {
        subject
        bot_instance.reload
      }.to change(bot_instance.events, :count).by(1)

      event = bot_instance.events.last

      expect(event.event_type).to eql 'message'
      expect(event.provider).to eql 'kik'
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
        subject
        bot_instance.reload
      }.to_not change(bot_instance.users, :count)
    end

    it 'should increment bot_interaction_count if is_for_bot, otherwise do not increment' do
      if is_for_bot
        expect {
          subject
          user.reload
        }.to change(user, :bot_interaction_count).from(0).to(1)
      else
        expect {
          subject
          user.reload
        }.to_not change(user, :bot_interaction_count)
      end
    end

    it "should set last_interacted_with_bot_at to the event's created_at timestamp if is_for_bot, otherwise don't do anything" do
      if is_for_bot
        expect {
          subject
          user.reload
        }.to change(user, :last_interacted_with_bot_at)

        expect(user.last_interacted_with_bot_at).to eql bot_instance.events.last.created_at
      else
        expect {
          subject
          user.reload
        }.to_not change(user, :last_interacted_with_bot_at)
      end
    end
  end

  describe '"text" events' do
    let(:kik_user_id)   { "kik-user-id"  }
    let(:bot_user_id)   { bot.uid        }
    let(:text)          { "hello-world"  }
    let(:event_type)    { 'message'      }
    let(:is_from_bot)   { false }
    let(:is_for_bot)    { false  }
    let(:is_im)         { false  }
    let(:required_event_attributes) {
      Hash["id", "id-1", "chat_id", "chat_id-1"]
    }

    let(:events) {
      [
        {
          "chatId": required_event_attributes['chat_id'],
          "type": "text",
          "from": kik_user_id,
          "participants": ["laura"],
          "id": required_event_attributes['id'],
          "timestamp": timestamp,
          "body": text,
          "mention": nil
        }
      ]
    }

    context "bot user exists" do
      it_behaves_like "should create an event as well as create the bot users"
    end

    context "bot user does not exist" do
      it_behaves_like "should create an event but not create any bot users"
    end
  end

  describe '"delivery-receipt" event' do
    let(:kik_user_id)   { "kik-user-id"  }
    let(:bot_user_id)   { bot.uid        }
    let!(:user)         { create :bot_user, bot_instance: bot_instance, provider: 'kik' }
    let!(:kik_client)   { double(Kik) }
    let!(:first_name)   { Faker::Name.first_name }
    let!(:last_name)   { Faker::Name.last_name }
    let!(:profile_pic_url)           { Faker::Internet.url }
    let!(:profile_pic_last_modified) { Faker::Date.between(2.days.ago, Date.today)  }
    let!(:e1)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'kik',
                     event_attributes: { id: "id-1", chat_id: "chat_id-1", sub_type: 'text' }
    end
    let!(:e2)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'kik',
                     event_attributes: { id: "id-2", chat_id: "chat_id-1", sub_type: 'text' }
    end
    let!(:e3)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'kik',
                     event_attributes: { id: "id-3", chat_id: "chat_id-1", sub_type: 'text' }
    end

    before do
      allow(Kik).to receive(:new).with(bot_instance.token, bot_instance.uid).and_return(kik_client)

      allow(kik_client).to receive(:call).
                       with("user/#{kik_user_id}", :get).
                       and_return(firstName: first_name,
                                  lastName: last_name,
                                  profilePicUrl: profile_pic_url,
                                  profilePicLastModified: profile_pic_last_modified)
    end

    let(:events) {
      [
        {
          chatId: "chat_id",
          type: "delivery-receipt",
          from: kik_user_id,
          participants: [kik_user_id],
          id: "id",
          messageIds: ["id-1", "id-2"],
          timestamp: 1399303478832,
          readReceiptRequested: false,
          mention: nil
        }
      ]
    }

    it "should update the 'has_been_delivered' value for all of the events that belong to the bot_instance to 'true'" do
      subject
      expect(e1.reload.has_been_delivered).to be true
      expect(e2.reload.has_been_delivered).to be true
      expect(e3.reload.has_been_delivered).to be false
    end
  end

  describe '"read-receipt" event' do
    let(:kik_user_id)   { "kik-user-id"  }
    let(:bot_user_id)   { bot.uid        }
    let!(:user)         { create :bot_user, bot_instance: bot_instance, provider: 'kik' }
    let!(:kik_client)   { double(Kik) }
    let!(:first_name)   { Faker::Name.first_name }
    let!(:last_name)   { Faker::Name.last_name }
    let!(:profile_pic_url)           { Faker::Internet.url }
    let!(:profile_pic_last_modified) { Faker::Date.between(2.days.ago, Date.today)  }
    let!(:e1)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'kik',
                     event_attributes: { id: "id-1", chat_id: "chat_id-1", sub_type: 'text' }
    end
    let!(:e2)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'kik',
                     event_attributes: { id: "id-2", chat_id: "chat_id-1", sub_type: 'text' }
    end
    let!(:e3)    do
      create :event, user: user, bot_instance: bot_instance, event_type: 'message', provider: 'kik',
                     event_attributes: { id: "id-3", chat_id: "chat_id-1", sub_type: 'text' }
    end

    before do
      allow(Kik).to receive(:new).with(bot_instance.token, bot_instance.uid).and_return(kik_client)

      allow(kik_client).to receive(:call).
                       with("user/#{kik_user_id}", :get).
                       and_return(firstName: first_name,
                                  lastName: last_name,
                                  profilePicUrl: profile_pic_url,
                                  profilePicLastModified: profile_pic_last_modified)
    end

    let(:events) {
      [
        {
          chatId: "chat_id",
          type: "read-receipt",
          from: kik_user_id,
          participants: [kik_user_id],
          id: "id",
          messageIds: ["id-1", "id-2"],
          timestamp: 1399303478832,
          readReceiptRequested: false,
          mention: nil
        }
      ]
    }

    it "should update the 'has_been_read' value for all of the events that belong to the bot_instance to 'true'" do
      subject
      expect(e1.reload.has_been_read).to be true
      expect(e2.reload.has_been_read).to be true
      expect(e3.reload.has_been_read).to be false
    end
  end
end

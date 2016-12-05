RSpec.describe Event do
  describe 'associations' do
    it { should belong_to :bot_instance }
    it { should belong_to :user }
  end

  describe 'validations' do
    context 'regular validations' do
      subject { create :event }

      it { should validate_presence_of :event_type }
      it { should validate_presence_of :bot_instance_id }
      it { should validate_presence_of :provider }

      it { should allow_value('slack').for(:provider) }
      it { should allow_value('kik').for(:provider) }
      it { should allow_value('facebook').for(:provider) }
      it { should allow_value('telegram').for(:provider) }
      it { should_not allow_value('test').for(:provider) }

      it { should allow_value('user-added').for(:event_type) }
      it { should allow_value('bot_disabled').for(:event_type) }
      it { should allow_value('added_to_channel').for(:event_type) }
      it { should allow_value('message').for(:event_type) }
      it { should allow_value('message_reaction').for(:event_type) }
      it { should_not allow_value('test').for(:event_type) }
    end

    context 'kik' do
      let!(:user)  { create :bot_user }
      let!(:event) { build :event, event_type: 'message', user: user, event_attributes: { sub_type: 'text' }, provider: 'kik' }

      context 'event_attributes' do
        it "should be invalid if event_type = 'message' and id is NULL" do
          event.event_type = 'message'
          expect(event).to_not be_valid
          expect(event.errors[:event_attributes]).to eql ["id can't be blank"]
        end
      end

      context 'bot_user_id' do
        it "should be invalid if bot_user_id is nil" do
          event.event_type = 'message'
          event.event_attributes['id'] = 'id-1'
          event.event_attributes['chat_id'] = 'chat_id-1'
          event.bot_user_id = nil
          expect(event).to_not be_valid
          expect(event.errors[:bot_user_id]).to eql ["can't be blank"]
        end
      end

      context 'event_attributes -> sub_types' do
        AVAILABLE_TYPES = %w(text link picture video start-chatting scan-data sticker is-typing friend-picker).freeze

        AVAILABLE_TYPES.each_with_index do |v, i|
          let(:"correct_type#{i}") { build :event, user: user, event_type: 'message',
                                     event_attributes: { id: "id-#{i}", chat_id: 'chat_id-1', sub_type: v },
                                     provider: 'kik' }
        end

        let(:incorrect_type) { build :event, user: user, event_type: 'message',
                               event_attributes: { id: 'id-10', chat_id: 'chat_id-1', sub_type: 'incorrect' },
                               provider: 'kik' }

        it 'validate sub_type' do
          AVAILABLE_TYPES.count.times do |i|
            expect(eval("correct_type#{i}")).to be_valid
          end

          expect(incorrect_type).to_not be_valid
          expect(incorrect_type.errors[:event_attributes]).to eql ["incorrect sub_type"]
        end
      end
    end

    context 'facebook' do
      let!(:user)  { create :bot_user }
      let!(:event) { build :event, event_type: 'message', user: user, event_attributes: {}, provider: 'facebook' }

      context 'event_attributes' do
        it "should be invalid if event_type = 'message' and mid is NULL" do
          event.event_type = 'message'
          event.event_attributes['seq'] = '123456789.0'
          expect(event).to_not be_valid
          expect(event.errors[:event_attributes]).to eql ["mid can't be blank"]
        end

        it "should be invalid if event_type = 'message' and seq is NULL" do
          event.event_type = 'message'
          event.event_attributes['mid'] = '123456789.0'
          expect(event).to_not be_valid
          expect(event.errors[:event_attributes]).to eql ["seq can't be blank"]
        end
      end

      context 'bot_user_id' do
        it "should be invalid if bot_user_id is nil" do
          event.event_type = 'message'
          event.event_attributes['seq'] = '123456789.0'
          event.event_attributes['mid'] = '123456789.0'
          event.bot_user_id = nil
          expect(event).to_not be_valid
          expect(event.errors[:bot_user_id]).to eql ["can't be blank"]
        end
      end
    end

    context 'slack' do
      let!(:user)  { create :bot_user }
      let!(:event) { create :event, event_type: 'bot-installed', user: user, event_attributes: { 'timestamp': '123456789.0' }, provider: 'slack' }

      context 'bot_user_id' do
        it "should be invalid if bot_user_id is nil" do
          event.event_type = 'message'
          event.bot_user_id = nil
          expect(event).to_not be_valid
          expect(event.errors[:bot_user_id]).to eql ["can't be blank"]
        end

        it "should be valid if bot_user_id is nil but event_type is not message or message_reaction" do
          event.event_type = 'user-added'
          event.bot_user_id = nil
          expect(event).to be_valid
        end
      end

      context 'event attributes' do
        context 'reaction is not null' do
          it "should be invalid if event_type = 'message_reaction' and reaction is NULL" do
            event.event_type = 'message_reaction'
            event.event_attributes[:channel] = 'CDEAD1'
            event.event_attributes[:timestamp] = '123456789.0'
            expect(event).to_not be_valid
            expect(event.errors[:event_attributes]).to eql ["channel can't be blank"]
          end

          it "should be valid if event_type = 'message_reaction' and reaction is NOT NULL" do
            event.event_type = 'message_reaction'
            event.event_attributes[:channel] = 'CDEAD1'
            event.event_attributes[:reaction] = ':+1:'
            event.event_attributes[:timestamp] = '123456789.0'
            expect(event).to_not be_valid
            expect(event.errors[:event_attributes]).to eql ["channel can't be blank"]
          end
        end

        context 'channel is not null' do
          let!(:user)  { create :bot_user }
          let!(:event) { create :event, event_type: 'bot-installed', user: user, event_attributes: { 'timestamp': '123456789.0' }, provider: 'slack' }

          it "should be invalid if event_type = 'message' and channel IS NULL" do
            event.event_type = 'message'
            expect(event).to_not be_valid
            expect(event.errors[:event_attributes]).to eql ["channel can't be blank"]
          end

          it "should be invalid if event_type = 'message_reaction' and channel IS NULL" do
            event.event_type = 'message'
            expect(event).to_not be_valid
            expect(event.errors[:event_attributes]).to eql ["channel can't be blank"]
          end

          it "should be valid if event_type = 'message' and channel IS NOT NULL" do
            event.event_type = 'message'
            event.event_attributes['channel'] = 'CABCDEAD1'
            expect(event).to be_valid
          end

          it "should be valid if event_type = 'message_reaction' and channel IS NOT NULL" do
            event.event_type = 'message_reaction'
            event.event_attributes['channel'] = 'CABCDEAD1'
            expect(event).to be_valid
          end
        end
      end
    end
  end

  context 'scope' do
    let(:disabled_bi)          { create :bot_instance }
    let(:all_message_bi)       { create :bot_instance }
    let(:messages_to_bot_bi)   { create :bot_instance }
    let(:messages_from_bot_bi) { create :bot_instance }

    before do
      disabled_bi.events.create(event_type: 'bot_disabled')
      all_message_bi.events.create(event_type: 'message', is_from_bot: false)
      messages_to_bot_bi.events.create(event_type: 'message', is_for_bot: true)
      messages_from_bot_bi.events.create(event_type: 'message', is_from_bot: true)
    end

    describe '.with_disabled_bots' do
      it 'works' do
        events = Event.with_disabled_bots(BotInstance.all, Time.current.yesterday, Time.zone.tomorrow)

        expect(events.map(&:id)).to eq disabled_bi.events.ids
      end
    end

    describe '.with_all_messages' do
      it 'works' do
        events = Event.with_all_messages(BotInstance.all, Time.current.yesterday, Time.zone.tomorrow)

        expect(events.map(&:id)).to eq all_message_bi.events.ids
      end
    end

    describe '.with_messages_to_bot' do
      it 'works' do
        events = Event.with_messages_to_bot(BotInstance.all, Time.current.yesterday, Time.zone.tomorrow)

        expect(events.map(&:id)).to eq messages_to_bot_bi.events.ids
      end
    end

    describe '.with_messages_from_bot' do
      it 'works' do
        events = Event.with_messages_from_bot(BotInstance.all, Time.current.yesterday, Time.zone.tomorrow)

        expect(events.map(&:id)).to eq messages_from_bot_bi.events.ids
      end
    end
  end
end

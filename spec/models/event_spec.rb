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

  # These callbacks are handled by postgres triggers
  # so you won't find anything in the Ruby code
  context 'callbacks' do
    context 'event insert' do
      let!(:bot)    { create :bot, provider: 'slack' }
      let!(:owner)  { create :user }
      let!(:bc1)    { create :bot_collaborator, bot: bot, user: owner       }
      let!(:bi)     { create :bot_instance, bot: bot, provider: 'slack'     }
      let!(:user)   { create :bot_user, bot_instance: bi, provider: 'slack' }

      before do
        bot.create_default_dashboards_with!(owner)
        @now = Time.now.utc
      end

      context 'bot installed event' do
        let!(:dashboard) { bot.dashboards.find_by(dashboard_type: 'bots-installed') }

        it 'should create an entry in the RolledupEventQueue with the hour' do
          @e1 = create(:new_bot_event, bot_instance: bi, created_at: @now)
          @rolled_up_entry = RolledupEventQueue.find_by(dashboard_id: dashboard.id, bot_instance_id: bi.id)
          expect(@rolled_up_entry).to_not be_nil
          expect(@rolled_up_entry.created_at).to eql @now.beginning_of_hour
          expect(@rolled_up_entry.diff).to eql 1
        end
      end

      context 'message event' do
        let!(:dashboard) { bot.dashboards.find_by(dashboard_type: 'messages') }

        it 'should create an entry in the RolledupEventQueue with the hour' do
          @e1 = create(:all_messages_event, bot_instance: bi, user: user, created_at: @now)
          @rolled_up_entry = RolledupEventQueue.find_by(dashboard_id: dashboard.id, bot_instance_id: bi.id, bot_user_id: user.id)
          expect(@rolled_up_entry).to_not be_nil
          expect(@rolled_up_entry.created_at).to eql @now.beginning_of_hour
          expect(@rolled_up_entry.diff).to eql 1
        end
      end

      context 'message to bot event' do
        let!(:dashboard) { bot.dashboards.find_by(dashboard_type: 'messages-to-bot') }

        it 'should create an entry in the RolledupEventQueue with the hour' do
          @e1 = create(:messages_to_bot_event, bot_instance: bi, user: user, created_at: @now)
          @rolled_up_entry = RolledupEventQueue.find_by(dashboard_id: dashboard.id, bot_instance_id: bi.id, bot_user_id: user.id)
          expect(@rolled_up_entry).to_not be_nil
          expect(@rolled_up_entry.created_at).to eql @now.beginning_of_hour
          expect(@rolled_up_entry.diff).to eql 1
        end
      end

      context 'message from bot event' do
        let!(:dashboard) { bot.dashboards.find_by(dashboard_type: 'messages-from-bot') }

        it 'should create an entry in the RolledupEventQueue with the hour' do
          @e1 = create(:all_messages_event, is_from_bot: true, bot_instance: bi, user: user, created_at: @now)
          @rolled_up_entry = RolledupEventQueue.find_by(dashboard_id: dashboard.id, bot_instance_id: bi.id, bot_user_id: user.id)
          expect(@rolled_up_entry).to_not be_nil
          expect(@rolled_up_entry.created_at).to eql @now.beginning_of_hour
          expect(@rolled_up_entry.diff).to eql 1
        end
      end

      context 'custom dashboard' do
        let!(:dashboard) { create(:dashboard, dashboard_type: 'custom', regex: 'abc', bot: bot, user: owner) }

        it 'should create an entry in the RolledupEventQueue with the hour' do
          @e1 = create(:all_messages_event, is_from_bot: true, bot_instance: bi, user: user, created_at: @now)
          @dc1 = create(:dashboard_event, dashboard: dashboard, event: @e1)

          @rolled_up_entry = RolledupEventQueue.find_by(dashboard_id: dashboard.id, bot_instance_id: bi.id, bot_user_id: user.id)
          expect(@rolled_up_entry).to_not be_nil
          expect(@rolled_up_entry.created_at).to eql @now.beginning_of_hour
          expect(@rolled_up_entry.diff).to eql 1
        end
      end
    end
  end
end

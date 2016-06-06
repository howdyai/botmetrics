RSpec.describe User do
  context 'associations' do
    it { should have_many :bot_collaborators }
    it { should have_many(:bots).through(:bot_collaborators) }
  end

  context 'scope' do
    describe '#subscribed_to' do
      context 'email preference is true' do
        let(:user) { create(:user) }

        it 'returns user' do
          user.update(created_bot_instance: '1')

          expect(User.subscribed_to(:created_bot_instance)).to eq [user]
        end
      end

      context 'email preference is false' do
        let!(:user) { create(:user) }

        it 'returns empty' do
          user.update(created_bot_instance: '0')

          expect(User.subscribed_to(:created_bot_instance)).to be_blank
        end
      end
    end

    describe '.local_time_is_after' do
      let(:san_franciscan) { create(:user, timezone: 'America/Los_Angeles') }
      let(:singaporean) { create(:user, timezone: 'Asia/Singapore') }

      it "find people's local time is after 9" do
        travel_to Time.parse('6 June, 2016 09:30 +0800') do
          result = User.local_time_is_after(9)

          expect(result).to match_array [singaporean]
        end
      end
    end
  end

  context 'before actions' do
    describe '#init_email_preferences' do
      it 'inits on create' do
        user = User.new(attributes_for(:user))

        expect(user.email_preferences).to be_blank

        user.save!

        expect(user.email_preferences).
          to eq(
               {
                 'created_bot_instance'  => '1',
                 'disabled_bot_instance' => '1',
                 'daily_reports'         => '1'
               }
             )
      end
    end
  end

  context 'store accessors' do
    describe 'email_preferences' do
      it { expect(subject).to respond_to :created_bot_instance }
      it { expect(subject).to respond_to :disabled_bot_instance }
      it { expect(subject).to respond_to :daily_reports }
    end

    describe 'tracking_attributes' do
      it { expect(subject).to respond_to :last_daily_summary_sent_at }
    end
  end

  describe '#can_send_daily_summary?' do
    context 'never send' do
      it 'returns true' do
        user = build_stubbed(:user)

        expect(user.can_send_daily_summary?).to be true
      end
    end

    context 'exactly 24 hours' do
      it 'returns true' do
        travel_to Time.parse('6 June, 2016 09:00 +0800') do
          user = build_stubbed(:user, tracking_attributes: { 'last_daily_summary_sent_at': 24.hours.ago })

          expect(user.can_send_daily_summary?).to be true
        end
      end
    end

    context 'today not sent yet in Singapore 10:00 AM' do
      let(:timezone) { 'Asia/Singapore' }

      it 'pulls out user not sent yet' do
        travel_to Time.parse('6 June, 2016 10:00 +0800') do
          # Users sent
          create(:user, full_name: 'Sent', timezone: 'Asia/Singapore',
          tracking_attributes: Hash(last_daily_summary_sent_at: Time.current.to_i))
          create(:user, full_name: 'To Send', timezone: 'Asia/Singapore',
          tracking_attributes: Hash(last_daily_summary_sent_at: (24.hours.ago + 1.second).to_i))

          # Users to send
          to_send = create(:user, full_name: 'To Send', timezone: 'Asia/Singapore',
          tracking_attributes: Hash(last_daily_summary_sent_at: (24.hours.ago - 1.second).to_i))

          expect(User.find_each.map(&:can_send_daily_summary?)).to match_array [false, false, true]
        end
      end
    end
  end

  describe '#subscribed_to_daily_summary?' do
    it "returns true if daily_reports is '1'" do
      user = build_stubbed(:user, daily_reports: '1')

      expect(user).to be_subscribed_to_daily_summary
    end

    it "returns false if daily_reports is not '1'" do
      user = build_stubbed(:user, daily_reports: nil)

      expect(user).not_to be_subscribed_to_daily_summary
    end
  end
end

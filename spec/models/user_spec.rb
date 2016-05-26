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
  end
end

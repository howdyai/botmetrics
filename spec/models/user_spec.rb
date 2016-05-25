RSpec.describe User do
  context 'associations' do
    it { should have_many :bot_collaborators }
    it { should have_many(:bots).through(:bot_collaborators) }
  end

  context 'store accessors' do
    describe 'email_preferences' do
      it { expect(subject).to respond_to :created_bot_instance }
    end
  end

  context 'before actions' do
    describe '#init_email_preferences' do
      it 'inits on create' do
        user = User.new(attributes_for(:user))

        expect(user.email_preferences).to be_blank

        user.save!

        expect(user.email_preferences).to eq({ 'created_bot_instance' => '1' })
      end
    end
  end
end

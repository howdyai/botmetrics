RSpec.describe Bot do
  describe 'validations' do
    subject { create :bot, uid: SecureRandom.hex(12) }
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :provider }
    it { is_expected.to validate_uniqueness_of :uid }

    it { is_expected.to allow_value('slack').for(:provider) }
    it { is_expected.to allow_value('kik').for(:provider) }
    it { is_expected.to allow_value('facebook').for(:provider) }
    it { is_expected.to allow_value('telegram').for(:provider) }
    it { is_expected.to_not allow_value('test').for(:provider) }

    it { is_expected.to_not allow_value('1https://').for(:webhook_url) }
  end

  describe 'associations' do
    it { is_expected.to have_many :instances }
    it { is_expected.to have_many :bot_collaborators }
    it { is_expected.to have_many(:collaborators).through(:bot_collaborators) }
    it { is_expected.to have_many(:owners).through(:bot_collaborators) }
    it { is_expected.to have_many :notifications }
    it { is_expected.to have_many :webhook_events }
  end

  describe '#build_instance' do
    context 'instance with facebook provider exists' do
      let(:bot) { create(:bot, provider: :facebook) }
      let!(:bi_facebook) { create(:bot_instance, provider: :facebook, bot: bot) }
      let(:bot_instance_params) { { token: 'new_token', provider: 'facebook' } }

      it 'should assign new attributes and update instance record' do
        bot_instance = bot.build_instance(bot_instance_params)
        expect(bot_instance.id).to eql(bi_facebook.id)
        expect(bot_instance.token).to eql('new_token')
      end
    end

    context 'instance doesn`t exist' do
      let(:bot) { create(:bot) }
      let(:bot_instance_params) { { token: 'token', provider: 'slack' } }

      it 'should build new bot instance object' do
        bot_instance = bot.build_instance(bot_instance_params)
        expect(bot_instance.id).to be_nil
        expect(bot_instance.token).to eql('token')
        expect(bot_instance.provider).to eql('slack')
      end
    end
  end
end

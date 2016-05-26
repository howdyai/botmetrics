RSpec.describe Bot do
  describe 'validations' do
    subject { create :bot }
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :provider }
    it { is_expected.to validate_uniqueness_of :uid }

    it { is_expected.to allow_value('slack').for(:provider) }
    it { is_expected.to allow_value('kik').for(:provider) }
    it { is_expected.to allow_value('facebook').for(:provider) }
    it { is_expected.to allow_value('telegram').for(:provider) }
    it { is_expected.to_not allow_value('test').for(:provider) }

    it { is_expected.to_not allow_value('http://').for(:webhook_url) }
  end

  describe 'associations' do
    it { is_expected.to have_many :instances }
    it { is_expected.to have_many :bot_collaborators }
    it { is_expected.to have_many(:collaborators).through(:bot_collaborators) }
    it { is_expected.to have_many(:owners).through(:bot_collaborators) }
    it { is_expected.to have_many :notifications }
    it { is_expected.to have_many :webhook_events }
  end
end

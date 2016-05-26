RSpec.describe WebhookEvent do
  describe 'associations' do
    it { is_expected.to belong_to :bot }
  end
end

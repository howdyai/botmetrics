RSpec.describe WebhookHistory do
  describe 'associations' do
    it { is_expected.to belong_to :bot }
  end
end

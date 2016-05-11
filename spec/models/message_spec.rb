require 'rails_helper'

RSpec.describe Message do
  context 'associations' do
    it { is_expected.to belong_to :bot_instance }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of :bot_instance }
  end

  describe '#duplicate_provider_from_bot_instance' do
    it 'copies provider' do
      message =
        Message.create(
          bot_instance: create(:bot_instance, provider: 'slack'),
          message_attributes: { team_id: 'T123', user: 'U123'}
        )

      expect(message.reload.provider).to eq 'slack'
    end
  end
end

require 'rails_helper'

RSpec.describe Message do
  context 'associations' do
    it { is_expected.to belong_to :bot_instance }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of :bot_instance }
  end
end

require 'rails_helper'

RSpec.describe Notification do
  context 'associations' do
    it { is_expected.to belong_to :bot }
    it { is_expected.to have_many :messages }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of :content }
  end
end

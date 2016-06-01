RSpec.describe QuerySet do
  context 'associations' do
    it { is_expected.to have_many :queries }
    it { is_expected.to accept_nested_attributes_for :queries }
  end
end

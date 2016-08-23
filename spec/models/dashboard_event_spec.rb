require 'rails_helper'

RSpec.describe DashboardEvent, type: :model do
  describe 'validations' do
    subject { create :dashboard_event }

    it { should validate_presence_of :dashboard_id }
    it { should validate_presence_of :event_id }
    it { should validate_uniqueness_of(:dashboard_id).scoped_to(:event_id) }
  end

  describe 'associations' do
    it { should belong_to :event }
    it { should belong_to :dashboard }
  end
end

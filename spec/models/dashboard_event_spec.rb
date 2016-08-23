require 'rails_helper'

RSpec.describe DashboardEvent, type: :model do
  describe 'validations' do
    it { should validate_presence_of :dashboard_id }
    it { should validate_presence_of :event_id }
  end

  describe 'associations' do
    it { should belong_to :event }
    it { should belong_to :dashboard }
  end
end

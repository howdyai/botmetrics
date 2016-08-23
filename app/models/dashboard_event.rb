class DashboardEvent < ActiveRecord::Base
  validates_presence_of :dashboard_id, :event_id
  belongs_to :dashboard
  belongs_to :event

  validates_uniqueness_of :dashboard_id, scope: :event_id
end

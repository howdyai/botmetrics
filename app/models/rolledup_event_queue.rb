class RolledupEventQueue < ActiveRecord::Base
  self.table_name = 'rolledup_event_queue'

  belongs_to :bot_user
  belongs_to :bot_instance
  belongs_to :dashboard
end

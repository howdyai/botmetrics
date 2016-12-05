class RolledupEvent < ActiveRecord::Base
  belongs_to :bot_user
  belongs_to :bot_instance
  belongs_to :dashboard
end

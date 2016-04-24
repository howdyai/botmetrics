class BotUser < ActiveRecord::Base
  validates_presence_of :uid, :membership_type, :bot_instance_id, :provider

  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)
  belongs_to :bot_instance
end

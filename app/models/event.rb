class Event < ActiveRecord::Base
  validates_presence_of   :event_type, :bot_instance_id, :provider
  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)
  validates_inclusion_of  :event_type, in: %w(user_added bot_disabled added_to_channel message message_reaction)
  validates_presence_of   :bot_user_id, if: Proc.new { |e| e.event_type == 'message' || e.event_type == 'message_reaction' }

  belongs_to :user, foreign_key: 'bot_user_id', class_name: 'BotUser'
  belongs_to :bot_instance

  validates_with EventAttributesValidator
end

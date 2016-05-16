class Event < ActiveRecord::Base
  validates_presence_of   :event_type, :bot_instance_id, :provider
  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)
  validates_inclusion_of  :event_type, in: %w(user_added bot_disabled added_to_channel message message_reaction)
  validates_presence_of   :bot_user_id, if: Proc.new { |e| e.event_type == 'message' || e.event_type == 'message_reaction' }

  belongs_to :user, foreign_key: 'bot_user_id', class_name: 'BotUser'
  belongs_to :bot_instance

  validates_with EventAttributesValidator

  def self.with_disabled_bots(instances, start_time, end_time)
    where(bot_instance_id: instances.select(:id),
          event_type: 'bot_disabled',
          created_at: start_time..end_time)
  end

  def self.with_all_messages(instances, start_time, end_time)
    where(bot_instance_id: instances.select(:id),
          event_type: 'message',
          is_from_bot: false,
          created_at: start_time..end_time)
  end

  def self.with_messages_to_bot(instances, start_time, end_time)
    where(bot_instance_id: instances.select(:id),
          event_type: 'message',
          is_for_bot: true,
          created_at: start_time..end_time)
  end

  def self.with_messages_from_bot(instances, start_time, end_time)
    where(bot_instance_id: instances.select(:id),
          event_type: 'message',
          is_from_bot: true,
          created_at: start_time..end_time)
  end
end

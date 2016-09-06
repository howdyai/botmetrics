class Event < ActiveRecord::Base
  validates_presence_of  :event_type, :bot_instance_id, :provider
  validates_inclusion_of :provider, in: %w(slack kik facebook telegram)

  belongs_to :user, foreign_key: 'bot_user_id', class_name: 'BotUser'
  belongs_to :bot_instance

  validates_with EventAttributesValidator
  validates_with EventTypeValidator
  validates_with BotUserIdValidator

  store_accessor :event_attributes, :mid, :seq

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

  def self.with_messaging_postbacks(instances, start_time, end_time)
    where(bot_instance_id: instances.select(:id),
          event_type: 'messaging_postbacks',
          created_at: start_time..end_time)
  end

  def self.with_message_subtype(instances, start_time, end_time, type, provider)
    relation = where(bot_instance_id: instances.select(:id),
                     event_type: 'message',
                     created_at: start_time..end_time)
    case provider
    when 'facebook'
      relation.where("(event_attributes->>'attachments')::text IS NOT NULL AND (event_attributes->'attachments'->0->>'type')::text = ?", type)
    when 'kik'
      relation.where("(event_attributes->>'sub_type')::text IS NOT NULL AND (event_attributes->>'sub_type')::text = ?", type)
    end
  end
end

class BotUser < ActiveRecord::Base
  belongs_to :bot_instance

  validates_presence_of :uid, :membership_type, :bot_instance_id, :provider
  validates_uniqueness_of :uid, scope: :bot_instance_id
  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)

  def self.with_bot_instances(instances, start_time, end_time)
    where(bot_instance_id: instances.select(:id)).joins(:bot_instance).
    where("bot_instances.created_at" => start_time..end_time)
  end
end

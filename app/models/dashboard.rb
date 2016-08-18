class Dashboard < ActiveRecord::Base
  include WithUidUniqueness

  DEFAULT_SLACK_DASHBOARDS    = %w(bots-installed bots-uninstalled new-users messages messages-to-bot messages-from-bot)
  DEFAULT_FACEBOOK_DASHBOARDS = %w(new-users messages-to-bot messages-from-bot)
  DEFAULT_KIK_DASHBOARDS      = %w(new-users messages-to-bot messages-from-bot)

  validates_presence_of :name, :bot_id, :user_id, :provider, :dashboard_type
  validates_uniqueness_of :uid
  validates_uniqueness_of :name, scope: :bot_id

  validates_inclusion_of :provider, in: Bot::PROVIDERS.keys

  belongs_to :bot
  belongs_to :user

  attr_accessor :growth, :count, :data, :instances, :group_by, :current
  delegate :timezone, to: :user

  def init!
    @current = true if current.nil?

    if group_by == 'all-time'
      @data = case dashboard_type
             when 'bots-installed'    then  new_bots_collection.count
             when 'bots-uninstalled'  then  disabled_bots_collection.count
             when 'new-users'         then  new_users_collection.count
             when 'messages'          then  messages_collection.count
             when 'messages-to-bot'   then  messages_for_bot_collection.count
             when 'messages-from-bot' then  messages_from_bot_collection.count
             end
    else
      func = case group_by
             when 'today' then 'group_by_day'
             when 'this-week' then 'group_by_week'
             when 'this-month' then 'group_by_month'
             end

      @data = case dashboard_type
             when 'bots-installed'    then send func, new_bots_collection
             when 'bots-uninstalled'  then send func, disabled_bots_collection
             when 'new-users'         then send func, new_users_collection, 'bot_users.created_at'
             when 'messages'          then send func, messages_collection
             when 'messages-to-bot'   then send func, messages_for_bot_collection
             when 'messages-from-bot' then send func, messages_from_bot_collection
             end
    end
  end

  def growth
    growth_for(self.data)
  end

  def count
    count_for(self.data)
  end

  private
  def instance_ids
    @_instance_ids ||= instances.select(:id)
  end

  def new_bots_collection
    instances
  end

  def disabled_bots_collection
    Event.where(event_type: 'bot_disabled', bot_instance_id: instance_ids)
  end

  def new_users_collection
    BotUser.where(bot_instance_id: instance_ids).joins(:bot_instance)
  end

  def messages_collection
    Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: false)
  end

  def messages_for_bot_collection
    Event.where(bot_instance_id: instance_ids, event_type: 'message', is_for_bot: true)
  end

  def messages_from_bot_collection
    Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: true)
  end

  def group_by_day(collection, group_col = :created_at)
    collection.group_by_day(group_col, last: 7, time_zone: self.timezone).count
  end

  def group_by_week(collection, group_col = :created_at)
    collection.group_by_week(group_col, last: 4, time_zone: self.timezone).count
  end

  def group_by_month(collection, group_col = :created_at)
    collection.group_by_month(group_col, last: 12, time_zone: self.timezone).count
  end

  def count_for(var)
    if group_by == 'all-time'
      var
    else
      var.values[last_pos]
    end
  end

  def growth_for(var)
    return nil if self.group_by == 'all-time'

    GrowthCalculator.new(var.values, last_pos).call
  end

  def last_pos
    current ? -1 : -2
  end
end

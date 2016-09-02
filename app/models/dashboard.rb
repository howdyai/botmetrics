class Dashboard < ActiveRecord::Base
  include WithUidUniqueness

  DEFAULT_SLACK_DASHBOARDS    = %w(bots-installed bots-uninstalled new-users messages messages-to-bot messages-from-bot)
  DEFAULT_FACEBOOK_DASHBOARDS = %w(new-users messages-to-bot messages-from-bot user-actions)
  DEFAULT_KIK_DASHBOARDS      = %w(new-users messages-to-bot messages-from-bot)

  validates_presence_of :name, :bot_id, :user_id, :provider, :dashboard_type
  validates_uniqueness_of :uid
  validates_uniqueness_of :name, scope: :bot_id
  validates_presence_of :regex, if: Proc.new { |d| d.dashboard_type == 'custom' }

  validates_inclusion_of :provider, in: Bot::PROVIDERS.keys

  validates_with DashboardRegexValidator

  belongs_to :bot
  belongs_to :user
  has_many :dashboard_events
  has_many :events, through: :dashboard_events

  scope :custom, -> { where("dashboards.dashboard_type" => 'custom') }
  scope :enabled, -> { where("dashboards.enabled" => true) }

  attr_accessor :growth, :count, :data,
                :group_by, :current, :start_time, :end_time, :page,
                :should_tableize, :tableized

  attr_reader :instances
  delegate :timezone, to: :user

  def init!
    @current = true if current.nil?
    @instances = self.bot.instances.legit

    if group_by == 'all-time'
      @data = case dashboard_type
             when 'bots-installed'      then  new_bots_collection.count
             when 'bots-uninstalled'    then  disabled_bots_collection.count
             when 'new-users'           then  new_users_collection.count
             when 'messages'            then  all_messages_collection.count
             when 'messages-to-bot'     then  messages_to_bot_collection.count
             when 'messages-from-bot'   then  messages_from_bot_collection.count
             when 'user-actions'        then  messaging_postbacks_collection.count
             when 'custom'              then  custom_events_collection.count
             end
    else
      func = case group_by
             when 'today', 'day' then 'group_by_day'
             when 'this-week', 'week' then 'group_by_week'
             when 'this-month', 'month' then 'group_by_month'
             end

      @data = case dashboard_type
              when 'bots-installed'      then send(func, new_bots_collection)
              when 'bots-uninstalled'    then send(func, disabled_bots_collection)
              when 'new-users'           then send(func, new_users_collection, 'bot_users.created_at')
              when 'messages'            then send(func, all_messages_collection)
              when 'messages-to-bot'     then send(func, messages_to_bot_collection)
              when 'messages-from-bot'   then send(func, messages_from_bot_collection)
              when 'user-actions'        then send(func, messaging_postbacks_collection)
              when 'custom'              then send(func, custom_events_collection, 'events.created_at')
              end

      if self.should_tableize
        @tableized = case dashboard_type
                     when 'bots-installed'    then new_bots_tableized.page(page)
                     when 'bots-uninstalled'  then disabled_bots_tableized.page(page)
                     when 'new-users'         then new_users_tableized.page(page)
                     when 'messages'          then all_messages_tableized.page(page)
                     when 'messages-from-bot' then messages_from_bot_tableized.page(page)
                     when 'messages-to-bot'   then messages_to_bot_tableized.page(page)
                     when 'user-actions'      then messaging_postbacks_tableized.page(page)
                     when 'custom'            then custom_events_tableized.page(page)
                     end
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

  def new_bots_tableized
    instances.with_new_bots(@start_time, @end_time)
  end

  def disabled_bots_collection
    Event.where(event_type: 'bot_disabled', bot_instance_id: instance_ids)
  end

  def disabled_bots_tableized
    events = Event.with_disabled_bots(instances, @start_time.utc, @end_time.utc)
    instances.with_disabled_bots(events.select(:bot_instance_id))
  end

  def new_users_collection
    BotUser.where(bot_instance_id: instance_ids).joins(:bot_instance)
  end

  def new_users_tableized
    BotUser.with_bot_instances(@instances, self.bot, @start_time.utc, @end_time.utc).
            order("bot_users.created_at DESC")
  end

  def all_messages_collection
    Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: false)
  end

  def all_messages_tableized
    messages = Event.with_all_messages(@instances, @start_time.utc, @end_time.utc)
    @instances.with_all_messages(messages.select(:bot_instance_id))
  end

  def messages_to_bot_collection
    Event.where(bot_instance_id: instance_ids, event_type: 'message', is_for_bot: true)
  end

  def messages_to_bot_tableized
    messages = Event.with_messages_to_bot(@instances, @start_time.utc, @end_time.utc)

    case self.bot.provider
    when 'slack'
      @instances.with_messages_to_bot(messages.select(:bot_instance_id))
    when 'facebook'
      BotUser.with_messages_to_bot(messages.select(:bot_instance_id))
    end
  end

  def custom_events_tableized
    messages = self.events.where("events.created_at" => @start_time.utc..@end_time.utc)
    BotUser.with_events(messages.select(:bot_user_id), messages.pluck(:id))
  end

  def messages_from_bot_collection
    Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: true)
  end

  def messages_from_bot_tableized
    messages = Event.with_messages_from_bot(@instances, @start_time.utc, @end_time.utc)

    case self.bot.provider
    when 'slack'
      @instances.with_messages_from_bot(messages.select(:bot_instance_id))
    when 'facebook'
      BotUser.with_messages_from_bot(messages.select(:bot_instance_id))
    end
  end

  def messaging_postbacks_collection
    Event.where(bot_instance_id: instance_ids, event_type: 'messaging_postbacks')
  end

  def messaging_postbacks_tableized
    messages = Event.with_messaging_postbacks(@instances, @start_time.utc, @end_time.utc)
    BotUser.with_messaging_postbacks(messages.select(:bot_instance_id))
  end

  def custom_events_collection
    self.events
  end

  def group_by_day(collection, group_col = :created_at)
    collection.group_by_day(group_col, params).count
  end

  def group_by_week(collection, group_col = :created_at)
    collection.group_by_week(group_col, params).count
  end

  def group_by_month(collection, group_col = :created_at)
    collection.group_by_month(group_col, params).count
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

  def params
    if start_time && end_time
      default_params.merge!(range: start_time..end_time)
    else
      last = case group_by
             when 'day', 'today' then 7
             when 'this-week', 'week' then 4
             when 'this-month', 'month' then 12
             end
      default_params.merge!(last: last)
    end

    default_params
  end

  def default_params
    @_default_params ||= { time_zone: self.timezone }
  end
end

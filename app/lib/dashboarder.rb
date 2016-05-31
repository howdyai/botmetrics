class Dashboarder
  attr_reader :instances, :group_by, :timezone, :current,
              :new_bots, :disabled_bots, :new_users,
              :messages, :messages_for_bot, :messages_from_bot

  def initialize(instances, group_by, timezone, current = true)
    @instances = instances
    @group_by  = group_by
    @timezone  = timezone
    @current   = current
  end

  def init!
    case @group_by
    when 'today'
      @new_bots          = group_by_day new_bots_collection
      @disabled_bots     = group_by_day disabled_bots_collection
      @new_users         = group_by_day new_users_collection, 'bot_instances.created_at'
      @messages          = group_by_day messages_collection
      @messages_for_bot  = group_by_day messages_for_bot_collection
      @messages_from_bot = group_by_day messages_from_bot_collection
    when 'this-week'
      @new_bots          = group_by_week new_bots_collection
      @disabled_bots     = group_by_week disabled_bots_collection
      @new_users         = group_by_week new_users_collection, 'bot_instances.created_at'
      @messages          = group_by_week messages_collection
      @messages_for_bot  = group_by_week messages_for_bot_collection
      @messages_from_bot = group_by_week messages_from_bot_collection
    when 'this-month'
      @new_bots          = group_by_month new_bots_collection
      @disabled_bots     = group_by_month disabled_bots_collection
      @new_users         = group_by_month new_users_collection, 'bot_instances.created_at'
      @messages          = group_by_month messages_collection
      @messages_for_bot  = group_by_month messages_for_bot_collection
      @messages_from_bot = group_by_month messages_from_bot_collection
    when 'all-time'
      @new_bots          = new_bots_collection.count
      @disabled_bots     = disabled_bots_collection.count
      @new_users         = new_users_collection.count
      @messages          = messages_collection.count
      @messages_for_bot  = messages_for_bot_collection.count
      @messages_from_bot = messages_from_bot_collection.count
    end
  end

  def new_bots_count
    count_for(@new_bots)
  end

  def new_bots_growth
    growth_for(@new_bots)
  end

  def disabled_bots_count
    count_for(@disabled_bots)
  end

  def disabled_bots_growth
    growth_for(@disabled_bots)
  end

  def new_users_count
    count_for(@new_users)
  end

  def new_users_growth
    growth_for(@new_users)
  end

  def messages_count
    count_for(@messages)
  end

  def messages_growth
    growth_for(@messages)
  end

  def messages_for_bot_count
    count_for(@messages_for_bot)
  end

  def messages_for_bot_growth
    growth_for(@messages_for_bot)
  end

  def messages_from_bot_count
    count_for(@messages_from_bot)
  end

  def messages_from_bot_growth
    growth_for(@messages_from_bot)
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
    if self.group_by == 'all-time'
      nil
    else
      v1 = var.values[last_pos].to_i
      v2 = var.values[last_pos - 1].to_i
      if v2 == 0
        nil
      else
        (v1 - v2).to_f / v2
      end
    end
  end

  def last_pos
    current ? -1 : -2
  end
end

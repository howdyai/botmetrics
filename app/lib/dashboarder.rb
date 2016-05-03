class Dashboarder
  attr_reader :instances, :group_by, :timezone
  attr_reader :new_bots, :disabled_bots, :new_users,
              :messages, :messages_for_bot, :messages_from_bot

  def initialize(instances, group_by, timezone)
    @instances = instances
    @group_by = group_by
    @timezone = timezone
  end

  def init!
    instance_ids = self.instances.select(:id)

    case @group_by
    when 'today'
      @new_bots = self.instances.group_by_day(:created_at, last: 7, time_zone: self.timezone).count
      @disabled_bots = Event.where(event_type: 'bot_disabled', bot_instance_id: instance_ids).
        group_by_day(:created_at, last: 7, time_zone: self.timezone).count
      @new_users = BotUser.where(bot_instance_id: instance_ids).
        group_by_day(:created_at, last: 7, time_zone: self.timezone).count
      @messages = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: false).
        group_by_day(:created_at, last: 7, time_zone: self.timezone).count
      @messages_for_bot = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_for_bot: true).
        group_by_day(:created_at, last: 7, time_zone: self.timezone).count
      @messages_from_bot = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: true).
        group_by_day(:created_at, last: 7, time_zone: self.timezone).count
    when 'this-week'
      @new_bots = self.instances.
        group_by_week(:created_at, last: 4, time_zone: self.timezone).count
      @disabled_bots = Event.where(event_type: 'bot_disabled', bot_instance_id: instance_ids).
        group_by_week(:created_at, last: 4, time_zone: self.timezone).count
      @new_users = BotUser.where(bot_instance_id: instance_ids).
        group_by_week(:created_at, last: 4, time_zone: self.timezone).count
      @messages = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: false).
        group_by_week(:created_at, last: 4, time_zone: self.timezone).count
      @messages_for_bot = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_for_bot: true).
        group_by_week(:created_at, last: 4, time_zone: self.timezone).count
      @messages_from_bot = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: true).
        group_by_week(:created_at, last: 4, time_zone: self.timezone).count
    when 'this-month'
      @new_bots = self.instances.
        group_by_month(:created_at, last: 12, time_zone: self.timezone).count
      @disabled_bots = Event.where(event_type: 'bot_disabled', bot_instance_id: instance_ids).
        group_by_month(:created_at, last: 12, time_zone: self.timezone).count
      @new_users = BotUser.where(bot_instance_id: instance_ids).
        group_by_month(:created_at, last: 12, time_zone: self.timezone).count
      @messages = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: false).
        group_by_month(:created_at, last: 12, time_zone: self.timezone).count
      @messages_for_bot = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_for_bot: true).
        group_by_month(:created_at, last: 12, time_zone: self.timezone).count
      @messages_from_bot = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: true).
        group_by_month(:created_at, last: 12, time_zone: self.timezone).count
    when 'all-time'
      @new_bots = self.instances.count
      @disabled_bots = Event.where(event_type: 'bot_disabled', bot_instance_id: instance_ids).count
      @new_users = BotUser.where(bot_instance_id: instance_ids).count
      @messages = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: false).count
      @messages_for_bot = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_for_bot: true).count
      @messages_from_bot = Event.where(bot_instance_id: instance_ids, event_type: 'message', is_from_bot: true).count
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
  def count_for(var)
    self.group_by == 'all-time' ? var : var.values.last
  end

  def growth_for(var)
    if self.group_by == 'all-time'
      nil
    else
      len = var.values.length

      v1 = var.values[len-1].to_i
      v2 = var.values[len-2].to_i
      if v2 == 0
        nil
      else
        (v1 - v2).to_f / v2
      end
    end
  end
end

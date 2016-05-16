# frozen_string_literal: true

class GetBotInstancesCountByUnit
  def initialize(unit, instances, start_time, end_time, user_time_zone)
    @unit = unit
    @instances = instances
    @start_time = start_time
    @end_time = end_time
    @user_time_zone = user_time_zone
  end

  def call
    case unit
    when 'day'
      instances.group_by_day("bot_instances.created_at", range: start_time..end_time, time_zone: user_time_zone).count
    when 'week'
      instances.group_by_week("bot_instances.created_at", range: start_time..end_time, time_zone: user_time_zone).count
    when 'month'
      instances.group_by_month("bot_instances.created_at", range: start_time..end_time, time_zone: user_time_zone).count
    end
  end

  private

    attr_reader :unit, :instances, :start_time, :end_time, :user_time_zone
end

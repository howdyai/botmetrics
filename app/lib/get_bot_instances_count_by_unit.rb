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
    instances.send(
      :"group_by_#{unit}",
      "#{instances.table_name}.created_at",
      params
    ).count
  end

  private

    attr_reader :unit, :instances, :start_time, :end_time, :user_time_zone

    def params
      default_params.merge!(range: start_time..end_time) if start_time && end_time
      default_params
    end

    def default_params
      @_default_params ||= { time_zone: user_time_zone }
    end
end

# frozen_string_literal: true

class GetResourcesCountByUnit
  def initialize(unit, resources, start_time: nil, end_time: nil, user_time_zone: nil)
    @unit = unit
    @resources = resources
    @start_time = start_time
    @end_time = end_time
    @user_time_zone = user_time_zone
  end

  def call
    resources.send(
      :"group_by_#{unit}",
      "#{resources.table_name}.created_at",
      params
    ).count
  end

  private

    attr_reader :unit, :resources, :start_time, :end_time, :user_time_zone

    def params
      default_params.merge!(range: start_time..end_time) if start_time && end_time
      default_params
    end

    def default_params
      @_default_params ||= { time_zone: user_time_zone }
    end
end

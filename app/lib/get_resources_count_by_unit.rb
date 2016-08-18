class GetResourcesCountByUnit
  def initialize(unit, resources, group_table: nil, start_time: nil, end_time: nil, user_time_zone: nil)
    @unit           = unit
    @resources      = resources
    @group_table    = group_table || resources.table_name
    @start_time     = start_time
    @end_time       = end_time
    @user_time_zone = user_time_zone
  end

  def call
    resources.send(
      :"group_by_#{unit}",
      "#{group_table}.created_at",
      params
    ).count
  end

  private
  attr_reader :unit, :resources, :group_table, :start_time, :end_time, :user_time_zone

  def params
    default_params.merge!(range: start_time..end_time) if start_time && end_time
    default_params
  end

  def default_params
    @_default_params ||= { time_zone: user_time_zone }
  end
end

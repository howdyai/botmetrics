class SetMixpanelPropertyJob < Job
  def perform(user_id, property, value=nil)
    @properties = property.kind_of?(Hash) ? property : { property => value }

    user = User.find_by id: user_id
    return unless user

    mixpanel = Mixpanel::Tracker.new Settings.mixpanel_token
    ignore_time = !!@properties.delete('$ignore_time')

    mixpanel.people.set(user.id, @properties, nil, {'$ignore_time' => ignore_time})
  end
end

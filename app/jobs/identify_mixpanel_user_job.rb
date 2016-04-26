class IdentifyMixpanelUserJob < Job
  def perform(user_id, attributes = {})
    email = nil
    mixpanel_params = {}

    user = User.find(user_id)
    email = user.email
    mixpanel_params = {
                        '$email' => user.email,
                        created: user.created_at.as_json,
                        ip: user.current_sign_in_ip,
                        '$full_name' => user.full_name,
                        '$first_name' => user.first_name,
                        '$last_name' => user.last_name,
                     }

    distinct_id = attributes.delete('distinct_id') || attributes.delete(:distinct_id)

    if(mixpanel_properties = user.mixpanel_properties).present?
      mixpanel_params.merge!(mixpanel_properties)
    end

    mixpanel_params.merge!(attributes)

    mixpanel = Mixpanel::Tracker.new(Settings.mixpanel_token)
    mixpanel.alias(user.id, distinct_id) if distinct_id
    mixpanel.people.set user.id, mixpanel_params
  end
end

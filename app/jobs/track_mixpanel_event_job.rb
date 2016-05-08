class TrackMixpanelEventJob < Job
  def perform(event, user_id = nil, properties={})
    default_properties = {}

    if user_id.present?
      user = User.find_by(id: user_id)
      if user
        default_properties = { '$email' => user.email,
                               '$full_name' => user.full_name,
                               '$first_name' => user.first_name,
                               '$last_name' => user.last_name,
                             }

        if (mixpanel_properties = user.mixpanel_properties).present?
          default_properties.merge!(mixpanel_properties)
        end

        default_properties.merge!(properties)
      end

      mixpanel = Mixpanel::Tracker.new(Settings.mixpanel_token)
      mixpanel.track user_id, event, default_properties
    end
  end
end

module MailHelper
  def mixpanel_event_tracking_pixel(user, event_name)
    tracker = Mixpanel::Tracker.new(Settings.mixpanel_token)
    image_tag tracker.generate_tracking_url(user.id, event_name)
  end
end

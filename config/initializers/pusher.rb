require 'uri'

if (pusher_url = Settings.pusher_url).present?
  Pusher.url = pusher_url
  uri = URI.parse(pusher_url)

  Pusher.app_id = uri.path.match(/apps\/(\d+)$/)[1]
  Pusher.key = uri.user
  Pusher.secret = uri.password
else
  Pusher.app_id = Settings.pusher_app_id
  Pusher.key = Settings.pusher_api_key
  Pusher.secret = Settings.pusher_secret
end

Pusher.logger = Rails.logger
Pusher.encrypted = true

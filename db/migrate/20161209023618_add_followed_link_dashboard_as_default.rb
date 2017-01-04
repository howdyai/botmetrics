class AddFollowedLinkDashboardAsDefault < ActiveRecord::Migration
  def up
    execute "ALTER TABLE dashboards DROP CONSTRAINT valid_dashboard_type_on_dashboards"
    execute """
ALTER TABLE dashboards ADD CONSTRAINT valid_dashboard_type_on_dashboards
CHECK (
  (
    provider = 'slack' AND (
      dashboard_type = 'bots-installed' OR
      dashboard_type = 'bots-uninstalled' OR
      dashboard_type = 'new-users' OR
      dashboard_type = 'messages' OR
      dashboard_type = 'messages-to-bot' OR
      dashboard_type = 'messages-from-bot' OR
      dashboard_type = 'followed-link' OR
      dashboard_type = 'custom'
   )
  ) OR
  (
    provider = 'facebook' AND (
      dashboard_type = 'new-users' OR
      dashboard_type = 'messages-to-bot' OR
      dashboard_type = 'messages-from-bot' OR
      dashboard_type = 'user-actions' OR
      dashboard_type = 'get-started' OR
      dashboard_type = 'image-uploaded' OR
      dashboard_type = 'audio-uploaded' OR
      dashboard_type = 'video-uploaded' OR
      dashboard_type = 'file-uploaded' OR
      dashboard_type = 'location-sent' OR
      dashboard_type = 'followed-link' OR
      dashboard_type = 'custom'
    )
  ) OR
  (
    provider = 'kik' AND (
      dashboard_type = 'new-users' OR
      dashboard_type = 'messages-to-bot' OR
      dashboard_type = 'messages-from-bot' OR
      dashboard_type = 'image-uploaded' OR
      dashboard_type = 'link-uploaded' OR
      dashboard_type = 'video-uploaded' OR
      dashboard_type = 'scanned-data' OR
      dashboard_type = 'sticker-uploaded' OR
      dashboard_type = 'friend-picker-chosen' OR
      dashboard_type = 'followed-link' OR
      dashboard_type = 'custom'
    )
  ) OR (
    provider = 'telegram'
  )
)
    """

    Bot.find_each do |bot|
      owner = bot.owners.first
      if owner.blank?
        puts "omg owner blank for bot: #{bot.inspect}"
        next
      end

      bot.create_default_dashboards_with!(owner)
    end
  end

  def down
    Dashboard.where(dashboard_type: 'followed-link').delete_all

    execute "ALTER TABLE dashboards DROP CONSTRAINT valid_dashboard_type_on_dashboards"
    execute """
ALTER TABLE dashboards ADD CONSTRAINT valid_dashboard_type_on_dashboards
CHECK (
  (
    provider = 'slack' AND (
      dashboard_type = 'bots-installed' OR
      dashboard_type = 'bots-uninstalled' OR
      dashboard_type = 'new-users' OR
      dashboard_type = 'messages' OR
      dashboard_type = 'messages-to-bot' OR
      dashboard_type = 'messages-from-bot' OR
      dashboard_type = 'custom'
   )
  ) OR
  (
    provider = 'facebook' AND (
      dashboard_type = 'new-users' OR
      dashboard_type = 'messages-to-bot' OR
      dashboard_type = 'messages-from-bot' OR
      dashboard_type = 'user-actions' OR
      dashboard_type = 'get-started' OR
      dashboard_type = 'image-uploaded' OR
      dashboard_type = 'audio-uploaded' OR
      dashboard_type = 'video-uploaded' OR
      dashboard_type = 'file-uploaded' OR
      dashboard_type = 'location-sent' OR
      dashboard_type = 'custom'
    )
  ) OR
  (
    provider = 'kik' AND (
      dashboard_type = 'new-users' OR
      dashboard_type = 'messages-to-bot' OR
      dashboard_type = 'messages-from-bot' OR
      dashboard_type = 'image-uploaded' OR
      dashboard_type = 'link-uploaded' OR
      dashboard_type = 'video-uploaded' OR
      dashboard_type = 'scanned-data' OR
      dashboard_type = 'sticker-uploaded' OR
      dashboard_type = 'friend-picker-chosen' OR
      dashboard_type = 'custom'
    )
  ) OR (
    provider = 'telegram'
  )
)
    """
  end
end

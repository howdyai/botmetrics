class Dashboard < ActiveRecord::Base
  include WithUidUniqueness

  DEFAULT_SLACK_DASHBOARDS    = %w(bots-installed bots-uninstalled new-users messages messages-to-bot messages-from-bot)
  DEFAULT_FACEBOOK_DASHBOARDS = %w(new-users messages-to-bot messages-from-bot)
  DEFAULT_KIK_DASHBOARDS      = %w(new-users messages-to-bot messages-from-bot)

  validates_presence_of :name, :bot_id, :user_id, :provider, :dashboard_type
  validates_uniqueness_of :uid
  validates_uniqueness_of :name, scope: :bot_id

  validates_inclusion_of :provider, in: Bot::PROVIDERS.keys

  belongs_to :bot
  belongs_to :user

end

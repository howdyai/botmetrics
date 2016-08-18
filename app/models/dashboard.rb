class Dashboard < ActiveRecord::Base
  include WithUidUniqueness

  validates_presence_of :name, :bot_id, :user_id, :provider, :dashboard_type
  validates_uniqueness_of :uid
  validates_uniqueness_of :name, scope: :bot_id

  validates_inclusion_of :provider, in: Bot::PROVIDERS.keys

  belongs_to :bot
  belongs_to :user

end

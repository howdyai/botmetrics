class BotInstance < ActiveRecord::Base
  validates_presence_of :token, :bot_id, :provider
  validates_uniqueness_of :uid, :token
  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)
  validates_inclusion_of  :state, in: %w(pending enabled disabled)

  validates_presence_of :uid, if: Proc.new { |bi| bi.state != 'pending' }
  validates_with BotInstanceAttributesValidator

  belongs_to :bot
  has_many :users, class_name: 'BotUser'
end

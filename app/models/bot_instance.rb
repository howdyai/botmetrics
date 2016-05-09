class BotInstance < ActiveRecord::Base
  belongs_to :bot
  has_many :users, class_name: 'BotUser'
  has_many :events
  has_many :messages

  validates_presence_of :token, :bot_id, :provider
  validates_uniqueness_of :token
  validates_inclusion_of  :provider, in: %w(slack kik facebook telegram)
  validates_inclusion_of  :state, in: %w(pending enabled disabled)

  validates_presence_of :uid, if: Proc.new { |bi| bi.state == 'enabled' }
  validates_uniqueness_of :uid, if: Proc.new { |bi| bi.uid.present? }

  validates_with BotInstanceAttributesValidator

  scope :legit,     -> { where("state <> ?", 'pending') }
  scope :enabled,   -> { where("state = ?", 'enabled') }
  scope :disabled,  -> { where("state = ?", 'disabled') }

  def self.find_by_bot_and_team!(bot, team_id)
    bot_instance = BotInstance.where(bot_id: bot.id).where("instance_attributes->>'team_id' = ?", team_id).first
    bot_instance.presence || (raise ActiveRecord::RecordNotFound)
  end

  def import_users!
    slack_client = Slack.new(self.token)
    json_list = slack_client.call('users.list', :get)

    if json_list['ok'] == true
      BotInstance.with_advisory_lock("team-import-#{self.uid}") do
        json_list['members'].each do |user|
          u = self.users.find_by(uid: user['id']) || self.users.new(uid: user['id'], provider: 'slack')

          u.user_attributes['nickname'] = user['name']
          u.user_attributes['email'] = user['profile']['email']

          u.user_attributes['first_name'] = user['profile']['first_name']
          u.user_attributes['last_name'] = user['profile']['last_name']
          u.user_attributes['full_name'] = user['profile']['real_name']

          u.user_attributes['timezone'] = user['tz']
          u.user_attributes['timezone_description'] = user['tz_label']
          u.user_attributes['timezone_offset'] = user['tz_offset'].to_i
          u.membership_type = BotInstance.membership_type_from_hash(user)
          u.save!
        end
      end
    end
  end

  def self.membership_type_from_hash(user_hash)
    membership_type = nil

    if user_hash['deleted']
      membership_type = 'deleted'
    elsif user_hash['is_owner']
      membership_type = 'owner'
    elsif user_hash['is_admin']
      membership_type = 'admin'
    elsif user_hash['is_restricted']
      membership_type = 'guest'
    else
      membership_type = 'member'
    end

    membership_type
  end
end

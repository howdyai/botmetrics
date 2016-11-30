class Dashboard < ActiveRecord::Base
  include WithUidUniqueness

  DEFAULT_SLACK_DASHBOARDS    = %w(bots-installed bots-uninstalled new-users messages messages-to-bot messages-from-bot)
  DEFAULT_FACEBOOK_DASHBOARDS = %w(new-users messages-to-bot messages-from-bot user-actions image-uploaded audio-uploaded video-uploaded file-uploaded location-sent)
  DEFAULT_KIK_DASHBOARDS      = %w(new-users messages-to-bot messages-from-bot image-uploaded video-uploaded link-uploaded scanned-data sticker-uploaded friend-picker-chosen)

  validates_presence_of :name, :bot_id, :user_id, :provider, :dashboard_type
  validates_presence_of :event_type, if: Proc.new { |d| d.dashboard_type != 'custom' }

  validates_uniqueness_of :uid
  validates_uniqueness_of :name, scope: :bot_id
  validates_presence_of :regex, if: Proc.new { |d| d.dashboard_type == 'custom' }

  validates_inclusion_of :provider, in: Bot::PROVIDERS.keys

  validates_with DashboardRegexValidator

  belongs_to :bot
  belongs_to :user
  has_many :dashboard_events

  scope :custom, -> { where("dashboards.dashboard_type" => 'custom') }
  scope :enabled, -> { where("dashboards.enabled" => true) }

  attr_accessor :growth, :count, :data,
                :group_by, :current, :start_time, :end_time, :page,
                :should_tableize, :tableized

  attr_reader :instances
  delegate :timezone, to: :user

  def init!
    @current = true if current.nil?
    @instances = self.bot.instances.legit

    func = case group_by
           when 'hour'                then 'group_by_hour'
           when 'today', 'day'        then 'group_by_day'
           when 'this-week', 'week'   then 'group_by_week'
           when 'this-month', 'month' then 'group_by_month'
           else 'all_count'
           end

    @data = send(func, events)
    @tableized = events_tableized.page(page) if self.should_tableize
  end

  def growth
    growth_for(self.data)
  end

  def count
    count_for(self.data)
  end

  def all_count(events)
    events.count
  end

  def action_name
    self.name
  end

  def events
    if custom?
      Event.where(id: self.dashboard_events.select(:event_id))
    else
      relation = self.bot.events.where("events.event_type" => self.event_type)
      relation = relation.where(self.query_options) if self.query_options.present?
      relation
    end
  end

  def custom?
    self.dashboard_type == 'custom'
  end

  def action_name
    case self.dashboard_type
    when 'image-uploaded'       then 'Uploaded An Image'
    when 'video-uploaded'       then 'Uploaded A Video'
    when 'audio-uploaded'       then 'Uploaded An Audio'
    when 'link-uploaded'        then 'Uploaded A Link'
    when 'sticker-uploaded'     then 'Uploaded A Sticker'
    when 'scanned-data'         then 'Scanned Data'
    when 'friend-picker-chosen' then 'Chosen From Friend Picker'
    when 'file-uploaded'        then 'Uploaded A File'
    when 'location-sent'        then 'Sent Location'
    when 'user-actions'         then 'Clicked Button'
    else name
    end
  end

  def set_event_type_and_query_options!
    self.event_type = case self.dashboard_type
                        when 'messages'             then 'message'
                        when 'messages-from-bot'    then 'message'
                        when 'messages-to-bot'      then 'message'
                        when 'audio-uploaded'       then 'message:audio-uploaded'
                        when 'file-uploaded'        then 'message:file-uploaded'
                        when 'friend-picker-chosen' then 'message:friend-picker-chosen'
                        when 'image-uploaded'       then 'message:image-uploaded'
                        when 'link-uploaded'        then 'message:link-uploaded'
                        when 'location-sent'        then 'message:location-sent'
                        when 'scanned-data'         then 'message:scanned-data'
                        when 'sticker-uploaded'     then 'message:sticker-uploaded'
                        when 'video-uploaded'       then 'message:video-uploaded'
                        when 'new-users'            then 'user-added'
                        when 'bots-installed'       then 'bot-installed'
                        when 'bots-uninstalled'     then 'bot_disabled'
                        when 'user-actions'         then 'messaging_postbacks'
                      end
    self.query_options = if self.dashboard_type == 'messages-from-bot'
                      {is_from_bot: true}
                    elsif self.dashboard_type == 'messages-to-bot'
                      {is_for_bot: true}
                    else
                      {}
                    end
  end

  private
  def instance_ids
    @_instance_ids ||= instances.select(:id)
  end

  def events_tableized
    events = self.events.where("events.created_at" => @start_time.utc..@end_time.utc)
    case self.dashboard_type
    when 'bots-installed', 'bots-uninstalled'
      BotInstance.with_events(events.select(:bot_instance_id), events.pluck(:id))
    else
      if ((self.dashboard_type == 'messages' ||
           self.dashboard_type == 'messages-to-bot' ||
           self.dashboard_type == 'messages-from-bot') && self.provider == 'slack')
        BotInstance.with_events(events.select(:bot_instance_id), events.pluck(:id))
      else
        BotUser.with_events(events.select(:bot_user_id), events.pluck(:id))
      end
    end
  end

  def group_by_day(collection, group_col = :created_at)
    collection.group_by_day(group_col, params).count
  end

  def group_by_hour(collection, group_col = :created_at)
    collection.group_by_hour(group_col, params).count
  end

  def group_by_week(collection, group_col = :created_at)
    collection.group_by_week(group_col, params).count
  end

  def group_by_month(collection, group_col = :created_at)
    collection.group_by_month(group_col, params).count
  end

  def count_for(var)
    if group_by == 'all-time'
      var
    else
      var.values[last_pos]
    end
  end

  def growth_for(var)
    return nil if self.group_by == 'all-time'

    GrowthCalculator.new(var.values, last_pos).call
  end

  def last_pos
    current ? -1 : -2
  end

  def params
    if start_time && end_time
      default_params.merge!(range: start_time..end_time)
    else
      last = case group_by
             when 'day', 'today' then 7
             when 'this-week', 'week' then 4
             when 'this-month', 'month' then 12
             end
      default_params.merge!(last: last)
    end

    default_params
  end

  def default_params
    @_default_params ||= { time_zone: self.timezone }
  end

  def self.name_for(type)
    case type
    when 'image-uploaded' then 'Image Uploads'
    when 'audio-uploaded' then 'Audio Uploads'
    when 'video-uploaded' then 'Video Uploads'
    when 'file-uploaded'  then 'File Uploads'
    when 'location-sent'  then 'Locations Shared'
    else type.titleize
    end
  end
end

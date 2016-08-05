class FacebookEventsService
  AVAILABLE_FIELDS = %w(first_name last_name profile_pic locale timezone gender)
  AVAILABLE_OPTIONS = %i(bot_id events_json)

  def initialize(options = {})
    options.each do |key, val|
      instance_variable_set("@#{key.to_s}", val)
    end
    sanitize_options(options)
  end

  def create_events!
    serialized_params.each do |params|
      @params = params
      @bot_user = BotUser.first_or_initialize(uid: bot_user_uid)
      @bot_user.assign_attributes(bot_user_params)

      ActiveRecord::Base.transaction do
        @bot_user.save!
        @bot_user.events.create!(params[:data].merge(bot_instance_id: bot_instance.id))
      end
    end
  end

  private
  attr_accessor :events_json, :bot_id, :params

  def serialized_params
    EventSerializer.new(:facebook, events_json).serialize
  end

  def fetch_user
    facebook_client.call(bot_user_uid, :get,
      {
        fields: 'first_name,last_name,locale,timezone,gender'
      }
    )
  end

  def bot_user_params
    {
      user_attributes: fetch_user.slice(*AVAILABLE_FIELDS),
      bot_instance_id: bot_instance.id,
      provider: 'facebook',
      membership_type: 'mem_type'
    }
  end

  def facebook_client
    Facebook.new(bot_instance.token)
  end

  def bot_instance
    @bot_instance ||= BotInstance.find_by(bot_id: bot.id)
  end

  def bot_user_uid
    if params.dig(:data, :event_type) == 'message_echoes'
      params.dig(:recip_info, :recipient_id)
    else
      params.dig(:recip_info, :sender_id)
    end
  end

  def bot
    Bot.find_by(uid: bot_id)
  end

  def sanitize_options(options)
    options.slice!(*AVAILABLE_OPTIONS)
    AVAILABLE_OPTIONS.each do |option|
      raise "NoOptionSupplied: #{option}" unless options.keys.include?(option) && options[option].present?
    end
  end
end

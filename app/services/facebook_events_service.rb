class FacebookEventsService
  AVAILABLE_FIELDS = %w(first_name last_name profile_pic locale timezone gender)
  AVAILABLE_OPTIONS = %i(bot_id raw_data)

  def initialize(options = {})
    options.each do |key, val|
      instance_variable_set("@#{key.to_s}", val)
    end
    sanitize_options(options)
  end

  def create_event
    if @raw_data.is_a?(Hash)
      @data = @raw_data
      process
    elsif @raw_data.is_a?(Array)
      @raw_data.each do |raw_data|
        @data = raw_data
        process
      end
    end
  end

  private
  attr_accessor :raw_data, :data, :bot_id

  def process
    @bot_user = BotUser.first_or_initialize(uid: bot_user_uid)
    @bot_user.assign_attributes(bot_user_params)
    ActiveRecord::Base.transaction do
      @bot_user.save!
      @bot_user.events.create!(event_params[:data].merge(bot_instance_id: bot_instance.id))
    end
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

  def event_params
    EventSerializer.new(:facebook, data).serialize
  end

  def facebook_client
    Facebook.new(bot_instance.token)
  end

  def bot_instance
    @bot_instance ||= BotInstance.find_by(bot_id: bot_id)
  end

  def bot_user_uid
    if event_params.dig(:data, :event_type) == 'message_echoes'
      event_params.dig(:recip_info, :recipient_id)
    else
      event_params.dig(:recip_info, :sender_id)
    end
  end

  def sanitize_options(options)
    options.slice!(*AVAILABLE_OPTIONS)
    AVAILABLE_OPTIONS.each do |option|
      raise "NoOptionSupplied: #{option}" unless options.keys.include?(option)
    end
  end
end

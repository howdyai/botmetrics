class FacebookEventsService
  AVAILABLE_FIELDS = %w(first_name last_name profile_pic locale timezone gender)

  def initialize(provider, raw_data, bot_id)
    @provider = provider
    @raw_data = raw_data
    @bot_id = bot_id
  end

  def create_event
    if @raw_data.is_a?(Hash)
      process(@raw_data)
    elsif @raw_data.is_a?(Array)
      @raw_data.each do |raw_data|
        process(raw_data)
      end
    end
  end

  private
  attr_accessor :provider, :raw_data, :data, :bot_id

  def process(data)
    @data = data
    @bot_user = BotUser.first_or_initialize(uid: bot_user_uid)
    @bot_user.assign_attributes(bot_user_params)
    if @bot_user.save
      @bot_user.events.create(event_params[:data].merge(bot_instance_id: bot_instance.id))
    end
  end

  def fetch_user
    facebook.call(bot_user_uid, :get,
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
    EventSerializer.new(provider, data).serialize
  end

  def facebook
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
end

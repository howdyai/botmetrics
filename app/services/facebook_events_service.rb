class FacebookEventsService
  AVAILABLE_USER_FIELDS = %w(first_name last_name profile_pic locale timezone gender)
  AVAILABLE_OPTIONS     = %i(bot_id events)
  UPDATE_EVENTS         = { message_deliveries: :delivered, message_reads: :read }

  def initialize(bot_id:, events:)
    @bot_id = bot_id
    @events = events
  end

  # We are using find_by here, because in Facebook's case
  # only one instance of BotInstance will ever exist
  def bot_instance
    @bot_instance ||= BotInstance.find_by(bot_id: bot.id)
  end

  def bot
    @bot ||= Bot.find_by(uid: bot_id)
  end

  def create_events!
    serialized_params.each do |p|
      @params = p
      @bot_user = bot_instance.users.find_by(uid: bot_user_uid) || BotUser.new(uid: bot_user_uid)
      @bot_user.assign_attributes(bot_user_params) if @bot_user.new_record?
      @event_type = params.dig(:data, :event_type).to_sym

      if UPDATE_EVENTS.has_key?(@event_type)
        update_message_events!
      else
        create_message_events!
      end
    end
  end

  private
  attr_accessor :events, :bot_id, :params

  def update_message_events!
    query_params = ['message', false, params.dig(:data, :watermark)]

    case @event_type
    when :message_deliveries
      bot.events.where("event_type = ? AND (event_attributes->>'delivered' IS NULL OR event_attributes->>'delivered' = ?) AND created_at < ?", *query_params).each do |event|
        event.update(delivered: true)
      end
    when :message_reads
      bot.events.where("event_type = ? AND (event_attributes->>'read' IS NULL OR (event_attributes->>'read')::boolean = ?) AND created_at < ?", *query_params).each do |event|
        event.update(read: true)
      end
    end
  end

  def create_message_events!
    ActiveRecord::Base.transaction do
      @bot_user.save!
      @bot_user.events.create!(event_params)
    end
  end

  def serialized_params
    EventSerializer.new(:facebook, events).serialize
  end

  def event_params
    params.dig(:data).merge(bot_instance_id: bot_instance.id)
  end

  def fetch_user
    facebook_client.call(bot_user_uid,
                         :get,
                         fields: 'first_name,last_name,profile_pic,locale,timezone,gender').
                    stringify_keys
  end

  def bot_user_params
    {
      user_attributes: fetch_user.slice(*AVAILABLE_USER_FIELDS),
      bot_instance_id: bot_instance.id,
      provider: 'facebook',
      membership_type: 'user'
    }
  end

  def facebook_client
    Facebook.new(bot_instance.token)
  end


  def bot_user_uid
    if params.dig(:data, :event_type) == 'message_echoes'
      params.dig(:recip_info, :recipient_id)
    else
      params.dig(:recip_info, :sender_id)
    end
  end
end

class FacebookEventsService
  AVAILABLE_USER_FIELDS = %w(first_name last_name profile_pic locale timezone gender)
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
      @event_type = params.dig(:data, :event_type).to_sym

      if UPDATE_EVENTS.has_key?(@event_type)
        update_message_events!
      else
        @bot_user = bot_instance.users.find_by(uid: bot_user_uid) || BotUser.new(uid: bot_user_uid)
        @bot_user.assign_attributes(bot_user_params) if @bot_user.new_record?

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
      bot.events.where("event_type = ? AND has_been_delivered = ? AND created_at <= ?", *query_params).update_all(has_been_delivered: true)
    when :message_reads
      bot.events.where("event_type = ? AND has_been_read = ? AND created_at <= ?", *query_params).update_all(has_been_read: true)
    end
  end

  def create_message_events!
    ActiveRecord::Base.transaction do
      @bot_user.save!
      event = @bot_user.events.create!(event_params)

      if event.is_for_bot?
        @bot_user.increment!(:bot_interaction_count)
        @bot_user.update_attribute(:last_interacted_with_bot_at, event.created_at)
      end
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

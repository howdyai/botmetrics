module Messages
  class Slack < Base
    attr_accessor :team_id, :channel, :user, :text, :attachments

    validates_presence_of :team_id

    validates_presence_of :channel,     if: ->(obj) { obj.user.blank? }
    validates_presence_of :user,        if: ->(obj) { obj.channel.blank? }

    validates_presence_of :text,        if: ->(obj) { obj.attachments.blank? }
    validates_presence_of :attachments, if: ->(obj) { obj.text.blank? }

    def model_params
      {
        message_attributes: message_attributes,
        user: user,
        text: text,
        attachments: attachments
      }.delete_if { |_, v| v.blank? }
    end

    def save_for(bot_instance)
      message = bot_instance.messages.build(model_params)

      if valid? && message.save
        message
      else
        nil
      end
    end

    private

      def message_attributes
        { team_id: team_id, channel: channel }.delete_if { |_, v| v.blank? }
      end
  end
end

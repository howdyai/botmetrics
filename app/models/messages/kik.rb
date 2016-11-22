module Messages
  class Kik < Base
    attr_accessor :user, :text

    validates_presence_of :user
    validates_presence_of :text

    def model_params
      {
        message_attributes: message_attributes,
        text: text
      }.delete_if { |_, v| v.blank? }
    end

    def save_for(bot_instance, opts = {})
      message = bot_instance.messages.build(model_params.merge!(opts))

      if valid? && message.save
        message
      else
        nil
      end
    end

    private
    def message_attributes
      { user: user }.delete_if { |_, v| v.blank? }
    end
  end
end

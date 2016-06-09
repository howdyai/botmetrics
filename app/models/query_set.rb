class QuerySet < ActiveRecord::Base
  belongs_to :bot

  has_many :queries
  accepts_nested_attributes_for :queries

  validates_presence_of   :bot_id
  validates_presence_of   :instances_scope
  validates_inclusion_of  :instances_scope, in: %w(legit enabled)
  validates_presence_of   :time_zone

  def initial_user_collection
    case instances_scope
      when 'legit'
        BotUser.where(bot_instance: bot.instances.legit)
      when 'enabled'
        BotUser.where(bot_instance: bot.instances.enabled)
      else
        raise "Houston, we have a '#{instances_scope}' problem!"
    end
  end

  def to_form_params
    {
      query_set: {
        bot_id:             bot_id,
        instances_scope:    instances_scope,
        time_zone:          time_zone,
        queries_attributes: queries_attributes
      }
    }
  end

  private

    def queries_attributes
      queries.each_with_index.inject({}) do |hash, (query, index)|
        hash[index.to_s] = query.to_form_params
        hash
      end
    end
end

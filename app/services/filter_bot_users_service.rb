class FilterBotUsersService
  def initialize(bot, query_set)
    @bot       = bot
    @query_set = query_set
  end

  def scope
    collection = BotUser.where(bot_instance_id: legit_bot_instances.ids)

    query_set.queries.each do |query|
      next if query.value.blank?
      collection = collection.where(query.sql_params)
    end

    collection
  end

  private

    attr_accessor :bot, :query_set

    def legit_bot_instances
      bot.instances.legit
    end
end

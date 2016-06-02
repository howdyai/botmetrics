class FilterBotUsersService
  def initialize(bot, query_set, time_zone)
    @bot       = bot
    @query_set = query_set
    @time_zone = time_zone
  end

  def scope
    collection = BotUser.where(bot_instance_id: legit_bot_instances.ids)

    query_set.queries.each do |query|
      next if query.value.blank? && (query.min_value.blank? || query.max_value.blank?)

      collection = chain_to(collection, query)
    end

    sort(collection)
  end

  private

    attr_reader :bot, :query_set, :time_zone

    def legit_bot_instances
      bot.instances.legit
    end

    def chain_to(collection, query)
      case
        when query.is_string_query?
          chain_with_string_query(collection, query)
        when query.is_number_query?
          chain_with_number_query(collection, query)
        when query.is_datetime_query?
          chain_with_datetime_query(collection, query)
        else
          collection
      end
    end

    def chain_with_string_query(collection, query)
      case
        when query.method == 'equals_to'
          collection.user_attributes_eq(query.field, query.value)
        when query.method == 'contains'
          collection.user_attributes_cont(query.field, query.value)
        else
          collection
      end
    end

    # currently only for interaction_count
    def chain_with_number_query(collection, query)
      case
        when query.method == 'equals_to'
          collection.interaction_count_eq(bot.instances.legit, query.value)
        when query.method == 'between'
          collection.interaction_count_betw(bot.instances.legit, query.min_value, query.max_value)
        else
          collection
      end
    end

    # currently only for interacted_at
    def chain_with_datetime_query(collection, query)
      collection.interacted_at_betw(
        bot.instances.legit,
        query.min_value.in_time_zone(time_zone),
        query.max_value.in_time_zone(time_zone)
      )
    end

    def sort(collection)
      BotUser.order_by_last_event_at(collection)
    end
end

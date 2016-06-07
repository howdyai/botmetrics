# frozen_string_literal: true

class FilterBotUsersService
  def initialize(query_set)
    @query_set = query_set
  end

  def scope
    collection = initial_collection

    query_set.queries.each do |query|
      next if query.value.blank? && (query.min_value.blank? || query.max_value.blank?)

      collection = chain_to(collection, query)
    end

    sort(collection)
  end

  private

    attr_reader :query_set

    def initial_collection
      case query_set.instances_scope
        when 'legit'
          BotUser.where(bot_instance: query_set.bot.instances.legit)
        when 'enabled'
          BotUser.where(bot_instance: query_set.bot.instances.enabled)
        else
          raise "Houston, we have a '#{query_set.instances_scope}' problem!"
      end
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

    # Currently only for interaction_count
    def chain_with_number_query(collection, query)
      case
        when query.method == 'equals_to'
          collection.interaction_count_eq(query.value)
        when query.method == 'lesser_than'
          collection.interaction_count_lt(query.value)
        when query.method == 'greater_than'
          collection.interaction_count_gt(query.value)
        when query.method == 'between'
          collection.interaction_count_betw(
            query.min_value,
            query.max_value
          )
        else
          collection
      end
    end

    # Currently only for interacted_at and BotUser's created_at
    def chain_with_datetime_query(collection, query)
      if query.field == 'user_created_at'
        collection.user_signed_up_betw(
          query.min_value.in_time_zone(query_set.time_zone),
          query.max_value.in_time_zone(query_set.time_zone)
        )
      else
        collection.interacted_at_betw(
          query.min_value.in_time_zone(query_set.time_zone),
          query.max_value.in_time_zone(query_set.time_zone)
        )
      end
    end

    def sort(collection)
      BotUser.order_by_last_event_at(collection).includes(:bot_instance)
    end
end

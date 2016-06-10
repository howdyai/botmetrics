# frozen_string_literal: true

class FilterBotUsersService
  def initialize(query_set)
    @query_set = query_set
  end

  def scope
    collection = query_set.initial_user_collection

    query_set.queries.each do |query|
      next if query.value.blank? && (query.min_value.blank? || query.max_value.blank?)

      collection = chain_to(collection, query)
    end

    if no_need_to_sort?(collection)
      collection.includes(:bot_instance)
    else
      sort(collection)
    end
  end

  private

    attr_reader :query_set

    def chain_to(collection, query)
      case
        when query.is_string_query?
          chain_with_string_query(collection, query)
        when query.is_number_query?
          chain_with_number_query(collection, query)
        when query.is_datetime_query?
          chain_with_datetime_query(collection, query)
        when query.is_ago_query?
          chain_with_ago_query(collection, query)
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

    def chain_with_ago_query(collection, query)
      beginning_of_that_days_ago = (
        Time.current.in_time_zone(query_set.time_zone) - (query.value.to_i).days
      ).beginning_of_day

      case
        when query.method == 'lesser_than'
          collection.interacted_at_ago_lt(beginning_of_that_days_ago)
        when query.method == 'greater_than'
          collection.interacted_at_ago_gt(beginning_of_that_days_ago)
      end
    end

    def no_need_to_sort?(collection)
      return true if collection.blank?

      collection.any? { |element| element.respond_to?(:last_event_at) }
    end

    def sort(collection)
      BotUser.order_by_last_event_at(collection).includes(:bot_instance)
    end
end

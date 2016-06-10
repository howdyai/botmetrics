module Queries
  class Slack
    FIELDS  = {
      'nickname'          => 'Nickname',
      'email'             => 'Email',
      'full_name'         => 'Full Name',
      'interaction_count' => 'Number of Interactions with Bot',
      'interacted_at'     => 'Interacted With Bot',
      'interacted_at_ago' => 'Last Interacted With Bot',
      'user_created_at'   => 'Signed Up',
    }

    STRING_METHODS = {
      'equals_to' => 'Equals To',
      'contains'  => 'Contains'
    }

    NUMBER_METHODS = {
      'equals_to'    => 'Equals To',
      'lesser_than'  => 'Lesser Than',
      'greater_than' => 'Greater Than',
      'between'      => 'Between'
    }

    DATETIME_METHODS = {
      'between'   => 'Between'
    }

    AGO_METHODS = {
      'lesser_than'  => 'Lesser Than',
      'greater_than' => 'Greater Than',
    }

    def is_string_query?(field)
      field.in?(['nickname', 'email', 'full_name'])
    end

    def is_number_query?(field)
      field.in?(['interaction_count'])
    end

    def is_datetime_query?(field)
      field.in?(['interacted_at', 'user_created_at'])
    end

    def is_ago_query?(field)
      field.in?(['interacted_at_ago'])
    end

    def fields
      FIELDS
    end

    def string_methods
      STRING_METHODS
    end

    def number_methods
      NUMBER_METHODS
    end

    def datetime_methods
      DATETIME_METHODS
    end

    def ago_methods
      AGO_METHODS
    end
  end
end

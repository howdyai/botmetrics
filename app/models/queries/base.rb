module Queries
  class Field
    attr_accessor :id, :to_label

    def initialize(opts = {})
      opts.each { |k,v| self.send("#{k}=", v) }
    end
  end

  class Base
    DASHBOARDS = [
      'user-actions',
      'image-uploaded',
      'video-uploaded',
      'audio-uploaded',
      'file-uploaded',
      'location-sent',
      'link-uploaded',
      'scanned-data',
      'sticker-uploaded',
      'friend-picker-chosen',
    ]

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
      'between'   => 'Between',
      'lesser_than'  => 'Less Than',
      'greater_than' => 'More Than'
    }

    def is_number_query?(field)
      field.in?(['interaction_count'])
    end

    def is_datetime_query?(field)
      field.in?(['interacted_at', 'user_created_at']) || field.match(/\Adashboard:[0-9a-f]+\Z/).present?
    end

    def fields(bot)
      dashboard_hash = bot.dashboards.where(dashboard_type: DASHBOARDS + ['custom'], enabled: true).
                        inject({}) { |hash, d| hash["dashboard:#{d.uid}"] = d.action_name; hash }
      self.class::FIELDS.merge(dashboard_hash)
    end

    # Returns in format suitable for Simple Form's :grouped_select
    def select_fields_collection(bot)
      fields = [
        ["", self.class::FIELDS.map {|k,v| Queries::Field.new(id: k, to_label: v)}]
      ]

      if (rich_metrics = bot.dashboards.where(dashboard_type: DASHBOARDS, enabled: true).order("dashboard_type ASC")).count > 0
        fields << ["Rich Metrics", to_fields(rich_metrics)]
      end

      if (custom_metrics = bot.dashboards.where(dashboard_type: 'custom', enabled: true).order("dashboard_type ASC")).count > 0
        fields << ["Custom Metrics", to_fields(custom_metrics)]
      end

      fields
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

    def to_fields(relation)
      relation.map { |d| Queries::Field.new(id: "dashboard:#{d.uid}", to_label: d.action_name) }
    end
  end
end

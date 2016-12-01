class Event < ActiveRecord::Base
  validates_presence_of  :event_type, :bot_instance_id, :provider
  validates_inclusion_of :provider, in: %w(slack kik facebook telegram)

  belongs_to :user, foreign_key: 'bot_user_id', class_name: 'BotUser'
  belongs_to :bot_instance

  validates_with EventAttributesValidator
  validates_with EventTypeValidator
  validates_with BotUserIdValidator

  store_accessor :event_attributes, :mid, :seq

  def self.rollup!
    Event.connection.execute(<<-SQL
CREATE OR REPLACE FUNCTION custom_append_to_rolledup_events_queue_on_update()
RETURNS TRIGGER LANGUAGE plpgsql
AS $body$
DECLARE
  __bot_instance_id int;
  __bot_user_id int;
  __created_at timestamp;
BEGIN
    CASE TG_OP
    WHEN 'UPDATE' THEN
      SELECT events.bot_instance_id, events.bot_user_id, events.created_at INTO __bot_instance_id, __bot_user_id, __created_at FROM events WHERE events.id = NEW.event_id LIMIT 1;
      IF NOT FOUND THEN
        RETURN NULL;
      END IF;
      INSERT INTO rolledup_event_queue(bot_instance_id, bot_user_id, dashboard_id, diff, created_at)
        VALUES (__bot_instance_id, __bot_user_id, NEW.dashboard_id, +1, date_trunc('hour', __created_at));
    END CASE;
    RETURN NULL;
END;
$body$;

CREATE OR REPLACE FUNCTION append_to_rolledup_events_queue_on_update()
RETURNS TRIGGER LANGUAGE plpgsql
AS $body$
DECLARE
  __bot_id int;
  __dashboard_id int;
BEGIN
    CASE TG_OP
    WHEN 'UPDATE' THEN
      SELECT bot_instances.bot_id INTO __bot_id FROM bot_instances WHERE bot_instances.id = NEW.bot_instance_id LIMIT 1;
      IF NOT FOUND THEN
        RETURN NULL;
      END IF;

      IF NEW.event_type = 'message' AND NEW.is_from_bot = 't' THEN
        SELECT dashboards.id FROM dashboards INTO __dashboard_id WHERE dashboards.dashboard_type = 'messages-from-bot';
        IF NOT FOUND THEN
          RETURN NULL;
        END IF;
      ELSIF NEW.event_type = 'message' AND NEW.is_for_bot = 't' THEN
        SELECT dashboards.id FROM dashboards INTO __dashboard_id WHERE dashboards.dashboard_type = 'messages-to-bot';
        IF NOT FOUND THEN
          RETURN NULL;
        END IF;
      ELSE
        SELECT dashboards.id FROM dashboards INTO __dashboard_id WHERE dashboards.event_type = NEW.event_type AND dashboards.bot_id = __bot_id;
        IF NOT FOUND THEN
          RETURN NULL;
        END IF;
      END IF;

      INSERT INTO rolledup_event_queue(bot_instance_id, bot_user_id, dashboard_id, diff, created_at)
        VALUES (NEW.bot_instance_id, NEW.bot_user_id, __dashboard_id, +1, date_trunc('hour', NEW.created_at));

      IF random() < 0.0001 THEN  /* 1/10,000 probability */
         PERFORM flush_rolledup_event_queue();
      END IF;
    END CASE;

    RETURN NULL;
END;
$body$;

DROP TRIGGER IF EXISTS event_update ON events;
CREATE TRIGGER event_update after
UPDATE
ON events FOR each row
EXECUTE PROCEDURE append_to_rolledup_events_queue_on_update();

DROP TRIGGER IF EXISTS custom_event_update ON dashboard_events;
CREATE TRIGGER custom_event_update after
UPDATE
ON dashboard_events FOR each row
EXECUTE PROCEDURE custom_append_to_rolledup_events_queue_on_update();
SQL
                            )
    months = ["2016-04-01", "2016-05-01", "2016-06-01", "2016-07-01", "2016-08-01", "2016-09-01", "2016-10-01"]

    require 'benchmark'

    months.each do |month|
      puts "Starting month: #{month}"
      puts Benchmark.measure {
        date = Date.parse(month)
        Event.where("events.created_at" => date.beginning_of_month..date.end_of_month).update_all(updated_at: Time.now)
        RolledupEventQueue.connection.execute("SELECT flush_rolledup_event_queue();")
      }
    end

    start = Date.parse("2016-11-01")
    end_time = Date.parse("2016-11-20")

    Event.where("events.created_at" => start.beginning_of_day..end_time.end_of_day).update_all(updated_at: Time.now)
    RolledupEventQueue.connection.execute("SELECT flush_rolledup_event_queue();")

    Date.parse("2016-11-21").upto(Date.parse("2016-12-01")) do |date|
      puts "Starting day: #{date}"
      puts Benchmark.measure {
        Event.where("events.created_at" => date.beginning_of_day..date.end_of_day).update_all(updated_at: Time.now)
        RolledupEventQueue.connection.execute("SELECT flush_rolledup_event_queue();")
      }
    end

    Event.connection.execute("DROP TRIGGER IF EXISTS event_update ON events;")
    Event.connection.execute("DROP FUNCTION IF EXISTS append_to_rolledup_events_queue_on_update() CASCADE;")

    puts Benchmark.measure {
      DashboardEvent.update_all(updated_at: Time.now)
      RolledupEventQueue.connection.execute("SELECT flush_rolledup_event_queue();")
    }

    Event.connection.execute("DROP TRIGGER IF EXISTS custom_event_update ON events;")
    Event.connection.execute("DROP FUNCTION IF EXISTS custom_append_to_rolledup_events_queue_on_update() CASCADE;")
  end

  def created_at_string
    self.created_at.to_s('%Y-%m-%d %H:%M:%S.%N')
  end
end

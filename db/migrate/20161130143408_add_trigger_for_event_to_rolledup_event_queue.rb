class AddTriggerForEventToRolledupEventQueue < ActiveRecord::Migration
  def up
    execute <<-SQL
CREATE OR REPLACE FUNCTION custom_append_to_rolledup_events_queue()
RETURNS TRIGGER LANGUAGE plpgsql
AS $body$
DECLARE
  __bot_instance_id int;
  __bot_user_id int;
  __created_at timestamp;
BEGIN
    CASE TG_OP
    WHEN 'INSERT' THEN
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

CREATE OR REPLACE FUNCTION append_to_rolledup_events_queue()
RETURNS TRIGGER LANGUAGE plpgsql
AS $body$
DECLARE
  __bot_id int;
  __dashboard_id int;
BEGIN
    CASE TG_OP
    WHEN 'INSERT' THEN
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
    END CASE;

    RETURN NULL;
END;
$body$;

DROP TRIGGER IF EXISTS event_insert ON events;
CREATE TRIGGER event_insert after
INSERT
ON events FOR each row
EXECUTE PROCEDURE append_to_rolledup_events_queue();

DROP TRIGGER IF EXISTS custom_event_insert ON dashboard_events;
CREATE TRIGGER custom_event_insert after
INSERT
ON dashboard_events FOR each row
EXECUTE PROCEDURE custom_append_to_rolledup_events_queue();
SQL
  end

  def down
    execute <<-SQL
DROP TRIGGER IF EXISTS event_insert ON events;
DROP TRIGGER IF EXISTS custom_event_insert ON events;

DROP FUNCTION IF EXISTS append_to_rolledup_events_queue()
DROP FUNCTION IF EXISTS custom_append_to_rolledup_events_queue()
SQL
  end
end

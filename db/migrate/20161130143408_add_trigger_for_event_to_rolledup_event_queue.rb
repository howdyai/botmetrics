class AddTriggerForEventToRolledupEventQueue < ActiveRecord::Migration
  def up
    execute <<-SQL
CREATE OR REPLACE FUNCTION flush_rolledup_event_queue()
RETURNS bool
LANGUAGE plpgsql
AS $body$
DECLARE
    v_prunes int;
BEGIN
    IF NOT pg_try_advisory_xact_lock('rolledup_event_queue'::regclass::oid::bigint) THEN
         RAISE NOTICE 'skipping queue flush';
         RETURN false;
    END IF;

    WITH
    aggregated_queue AS (
        SELECT created_at, dashboard_id, bot_instance_id, bot_user_id, SUM(diff) AS value
        FROM data_daily_counts_queue
        GROUP BY created_at, bot_instance_id, bot_user_id
    ),
    perform_inserts AS (
        INSERT INTO rolledup_events(created_at, dashboard_id, bot_instance_id, count)
        SELECT created_at, dashboard_id, bot_instance_id, bot_user_id, value AS count
        FROM aggregated_queue
        ON CONFLICT (created_at, dashboard_id, bot_instance_id, bot_user_id) DO UPDATE SET
        count = rolledup_events.count + EXCLUDED.count;

        RETURNING 1
    ),
    perform_prune AS (
        DELETE FROM rolledup_event_queue
        RETURNING 1
    )
    SELECT
        (SELECT count(*) FROM perform_prune) prunes
    INTO v_prunes;

    RAISE NOTICE 'performed queue (hourly) flush: % prunes', v_prunes;

    RETURN true;
END;
$body$;


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

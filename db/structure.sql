--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: bot_instances; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE bot_instances (
    id integer NOT NULL,
    token character varying NOT NULL,
    uid character varying,
    bot_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    provider character varying NOT NULL,
    state character varying DEFAULT 'pending'::character varying NOT NULL,
    instance_attributes jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT uid_set_if_not_pending CHECK (((((state)::text = 'pending'::text) OR (((state)::text = 'enabled'::text) AND (uid IS NOT NULL))) OR (((state)::text = 'disabled'::text) AND (uid IS NOT NULL)))),
    CONSTRAINT valid_provider_on_bot_instances CHECK ((((((provider)::text = 'slack'::text) OR ((provider)::text = 'kik'::text)) OR ((provider)::text = 'facebook'::text)) OR ((provider)::text = 'telegram'::text))),
    CONSTRAINT validate_attributes_team_id CHECK (((((((instance_attributes ->> 'team_id'::text) IS NOT NULL) AND (length((instance_attributes ->> 'team_id'::text)) > 0)) AND ((provider)::text = 'slack'::text)) AND ((state)::text <> 'pending'::text)) OR (((state)::text = 'pending'::text) AND (instance_attributes IS NOT NULL)))),
    CONSTRAINT validate_attributes_team_name CHECK (((((((instance_attributes ->> 'team_name'::text) IS NOT NULL) AND (length((instance_attributes ->> 'team_name'::text)) > 0)) AND ((provider)::text = 'slack'::text)) AND ((state)::text <> 'pending'::text)) OR (((state)::text = 'pending'::text) AND (instance_attributes IS NOT NULL)))),
    CONSTRAINT validate_attributes_team_url CHECK (((((((instance_attributes ->> 'team_url'::text) IS NOT NULL) AND (length((instance_attributes ->> 'team_url'::text)) > 0)) AND ((provider)::text = 'slack'::text)) AND ((state)::text <> 'pending'::text)) OR (((state)::text = 'pending'::text) AND (instance_attributes IS NOT NULL))))
);


--
-- Name: bot_instances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bot_instances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_instances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bot_instances_id_seq OWNED BY bot_instances.id;


--
-- Name: bot_users; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE bot_users (
    id integer NOT NULL,
    uid character varying NOT NULL,
    user_attributes json DEFAULT '{}'::json NOT NULL,
    membership_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    bot_instance_id integer NOT NULL,
    provider character varying NOT NULL,
    CONSTRAINT valid_provider_on_bot_users CHECK ((((((provider)::text = 'slack'::text) OR ((provider)::text = 'kik'::text)) OR ((provider)::text = 'facebook'::text)) OR ((provider)::text = 'telegram'::text)))
);


--
-- Name: bot_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bot_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bot_users_id_seq OWNED BY bot_users.id;


--
-- Name: bots; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE bots (
    id integer NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    provider character varying NOT NULL,
    team_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT valid_provider_on_bots CHECK ((((((provider)::text = 'slack'::text) OR ((provider)::text = 'kik'::text)) OR ((provider)::text = 'facebook'::text)) OR ((provider)::text = 'telegram'::text)))
);


--
-- Name: bots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bots_id_seq OWNED BY bots.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE events (
    id integer NOT NULL,
    event_type character varying NOT NULL,
    bot_instance_id integer NOT NULL,
    bot_user_id integer,
    is_for_bot boolean DEFAULT false NOT NULL,
    "boolean" boolean DEFAULT false NOT NULL,
    event_attributes jsonb DEFAULT '{}'::jsonb NOT NULL,
    provider character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    is_im boolean DEFAULT false NOT NULL,
    CONSTRAINT valid_event_type_on_events CHECK (((((((event_type)::text = 'user_added'::text) OR ((event_type)::text = 'bot_disabled'::text)) OR ((event_type)::text = 'added_to_channel'::text)) OR (((event_type)::text = 'message'::text) AND (bot_user_id IS NOT NULL))) OR (((event_type)::text = 'message_reaction'::text) AND (bot_user_id IS NOT NULL)))),
    CONSTRAINT valid_provider_on_events CHECK ((((((provider)::text = 'slack'::text) OR ((provider)::text = 'kik'::text)) OR ((provider)::text = 'facebook'::text)) OR ((provider)::text = 'telegram'::text))),
    CONSTRAINT validate_attributes_channel CHECK (((((((event_attributes ->> 'channel'::text) IS NOT NULL) AND (length((event_attributes ->> 'channel'::text)) > 0)) AND ((provider)::text = 'slack'::text)) AND (((event_type)::text = 'message'::text) OR ((event_type)::text = 'message_reaction'::text))) OR ((((provider)::text = 'slack'::text) AND (((event_type)::text <> 'message'::text) AND ((event_type)::text <> 'message_reaction'::text))) AND (event_attributes IS NOT NULL)))),
    CONSTRAINT validate_attributes_reaction CHECK (((((((event_attributes ->> 'reaction'::text) IS NOT NULL) AND (length((event_attributes ->> 'reaction'::text)) > 0)) AND ((provider)::text = 'slack'::text)) AND ((event_type)::text = 'message_reaction'::text)) OR ((((provider)::text = 'slack'::text) AND ((event_type)::text <> 'message_reaction'::text)) AND (event_attributes IS NOT NULL)))),
    CONSTRAINT validate_attributes_timestamp CHECK (((((((event_attributes ->> 'timestamp'::text) IS NOT NULL) AND (length((event_attributes ->> 'timestamp'::text)) > 0)) AND ((provider)::text = 'slack'::text)) AND (((event_type)::text = 'message'::text) OR ((event_type)::text = 'message_reaction'::text))) OR (((((provider)::text = 'slack'::text) AND ((event_type)::text <> 'message'::text)) AND ((event_type)::text <> 'message_reaction'::text)) AND (event_attributes IS NOT NULL))))
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: team_memberships; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE team_memberships (
    id integer NOT NULL,
    team_id integer NOT NULL,
    user_id integer NOT NULL,
    membership_type character varying DEFAULT 'member'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: team_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE team_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE team_memberships_id_seq OWNED BY team_memberships.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE teams (
    id integer NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE teams_id_seq OWNED BY teams.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying NOT NULL,
    encrypted_password character varying NOT NULL,
    first_name character varying,
    last_name character varying,
    full_name character varying,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    timezone character varying NOT NULL,
    timezone_utc_offset integer NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bot_instances ALTER COLUMN id SET DEFAULT nextval('bot_instances_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bot_users ALTER COLUMN id SET DEFAULT nextval('bot_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bots ALTER COLUMN id SET DEFAULT nextval('bots_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_memberships ALTER COLUMN id SET DEFAULT nextval('team_memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams ALTER COLUMN id SET DEFAULT nextval('teams_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: bot_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY bot_instances
    ADD CONSTRAINT bot_instances_pkey PRIMARY KEY (id);


--
-- Name: bot_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY bot_users
    ADD CONSTRAINT bot_users_pkey PRIMARY KEY (id);


--
-- Name: bots_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY bots
    ADD CONSTRAINT bots_pkey PRIMARY KEY (id);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: team_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY team_memberships
    ADD CONSTRAINT team_memberships_pkey PRIMARY KEY (id);


--
-- Name: teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: bot_instances_team_id_uid; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX bot_instances_team_id_uid ON bot_instances USING btree (uid, ((instance_attributes -> 'team_id'::text))) WHERE ((provider)::text = 'slack'::text);


--
-- Name: index_bot_instances_on_bot_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_bot_instances_on_bot_id ON bot_instances USING btree (bot_id);


--
-- Name: index_bot_instances_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_bot_instances_on_token ON bot_instances USING btree (token);


--
-- Name: index_bot_users_on_bot_instance_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_bot_users_on_bot_instance_id ON bot_users USING btree (bot_instance_id);


--
-- Name: index_bot_users_on_uid_and_bot_instance_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_bot_users_on_uid_and_bot_instance_id ON bot_users USING btree (uid, bot_instance_id);


--
-- Name: index_bots_on_team_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_bots_on_team_id ON bots USING btree (team_id);


--
-- Name: index_bots_on_uid; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_bots_on_uid ON bots USING btree (uid);


--
-- Name: index_events_on_bot_instance_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_events_on_bot_instance_id ON events USING btree (bot_instance_id);


--
-- Name: index_events_on_bot_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_events_on_bot_user_id ON events USING btree (bot_user_id);


--
-- Name: index_team_memberships_on_user_id_and_team_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_team_memberships_on_user_id_and_team_id ON team_memberships USING btree (user_id, team_id);


--
-- Name: index_teams_on_uid; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_teams_on_uid ON teams USING btree (uid);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: unique_bot_instance_uid; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX unique_bot_instance_uid ON bot_instances USING btree (uid) WHERE (uid IS NOT NULL);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: fk_rails_5aba9331a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_memberships
    ADD CONSTRAINT fk_rails_5aba9331a7 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_61c29b529e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_memberships
    ADD CONSTRAINT fk_rails_61c29b529e FOREIGN KEY (team_id) REFERENCES teams(id);


--
-- Name: fk_rails_6897853d8c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bot_instances
    ADD CONSTRAINT fk_rails_6897853d8c FOREIGN KEY (bot_id) REFERENCES bots(id);


--
-- Name: fk_rails_6e79174e50; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT fk_rails_6e79174e50 FOREIGN KEY (bot_user_id) REFERENCES bot_users(id);


--
-- Name: fk_rails_9fc3b26d0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT fk_rails_9fc3b26d0b FOREIGN KEY (bot_instance_id) REFERENCES bot_instances(id);


--
-- Name: fk_rails_aed385ebc5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bots
    ADD CONSTRAINT fk_rails_aed385ebc5 FOREIGN KEY (team_id) REFERENCES teams(id);


--
-- Name: fk_rails_d232307517; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bot_users
    ADD CONSTRAINT fk_rails_d232307517 FOREIGN KEY (bot_instance_id) REFERENCES bot_instances(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20160421235326');

INSERT INTO schema_migrations (version) VALUES ('20160422181209');

INSERT INTO schema_migrations (version) VALUES ('20160422182306');

INSERT INTO schema_migrations (version) VALUES ('20160422202903');

INSERT INTO schema_migrations (version) VALUES ('20160422204548');

INSERT INTO schema_migrations (version) VALUES ('20160422225034');

INSERT INTO schema_migrations (version) VALUES ('20160422230945');

INSERT INTO schema_migrations (version) VALUES ('20160422232133');

INSERT INTO schema_migrations (version) VALUES ('20160424150625');

INSERT INTO schema_migrations (version) VALUES ('20160424151249');

INSERT INTO schema_migrations (version) VALUES ('20160424153627');

INSERT INTO schema_migrations (version) VALUES ('20160424154450');

INSERT INTO schema_migrations (version) VALUES ('20160424154957');

INSERT INTO schema_migrations (version) VALUES ('20160424155854');

INSERT INTO schema_migrations (version) VALUES ('20160424161341');

INSERT INTO schema_migrations (version) VALUES ('20160424162744');

INSERT INTO schema_migrations (version) VALUES ('20160424201054');

INSERT INTO schema_migrations (version) VALUES ('20160424222520');

INSERT INTO schema_migrations (version) VALUES ('20160425163211');

INSERT INTO schema_migrations (version) VALUES ('20160425164622');

INSERT INTO schema_migrations (version) VALUES ('20160425212125');

INSERT INTO schema_migrations (version) VALUES ('20160425215210');

INSERT INTO schema_migrations (version) VALUES ('20160425220237');

INSERT INTO schema_migrations (version) VALUES ('20160425223534');


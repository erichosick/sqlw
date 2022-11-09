/* Copyright (c) 2022 Eric Hosick All Rights Reserved */

-- SECURITY --------------------------------------------------------------------

-- limit ability of new roles to do things in public schema such as
-- create table
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- SCHEMA ----------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS universal;
COMMENT ON SCHEMA universal IS 'contains sql assets, such as domains, types, triggers, etc., that are shared by other schema';

-- EXTENSIONS ------------------------------------------------------------------

-- Support case-insenstive types like email and url.
-- https://www.postgresql.org/docs/current/citext.html
CREATE EXTENSION IF NOT EXISTS citext;

-- -----------------------------------------------------------------------------

-- NOTE: Only superuser can create a LEAKPROOF function
CREATE OR REPLACE FUNCTION universal.uuid_bot()
RETURNS uuid LANGUAGE sql STRICT IMMUTABLE PARALLEL RESTRICTED AS $$
  SELECT '00000000-0000-0000-0000-000000000001'::uuid;
$$;
COMMENT ON FUNCTION universal.uuid_bot() IS 'Returns the persona_id (uuid) of the "bot" account hard coded to ''00000000-0000-0000-0000-000000000001''. Used when data is populated by the sql script.';

-- URL -------------------------------------------------------------------------

-- TODO: Finish out this code to pull out parts of a url
-- NOTE: Only superuser can create a LEAKPROOF function
CREATE OR REPLACE FUNCTION universal.url_parts(
  IN p_uri varchar(2047)
)
RETURNS RECORD LANGUAGE sql STRICT IMMUTABLE PARALLEL RESTRICTED AS $$
  SELECT 1 AS result;
$$;
COMMENT ON FUNCTION universal.url_parts(varchar) IS 'pulls out parts of a url. See https://developer.mozilla.org/en-US/docs/Web/API/Location';

-- see https://stackoverflow.com/questions/417142/what-is-the-maximum-length-of-a-url-in-different-browsers
DO $$ BEGIN
  CREATE DOMAIN universal.url AS citext
    CONSTRAINT shared_url_is_invalid
      CHECK (
        NOT universal.url_parts(VALUE) IS NULL
        AND CHAR_LENGTH(VALUE) <= 2047
      );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN universal.url IS 'A url (universal resource locator).';

-- Human readable types --------------------------------------------------------

DO $$ BEGIN
  CREATE DOMAIN universal.label AS varchar(128);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN universal.label IS 'A label is a human readable value often used in, drop down list box, as a check box label, radio label, etc.';

-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE DOMAIN universal.label_short AS varchar(32);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN universal.label_short IS 'A short label is a human readable value used in situations where there isn not a lot of screen space in the ui.';

-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE DOMAIN universal.title AS varchar(128)
    CHECK (CHAR_LENGTH(VALUE) <= 128);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN universal.title IS 'A title is a human readable value often used in, drop down list box, as a check box label, radio label, etc.';

-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE DOMAIN universal.description AS varchar(4096);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN universal.description IS 'A description is a human readable value providing detailed information about an entry used for things like tool-tips, documentation, explanations, etc.';

-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE DOMAIN universal.name AS varchar(512);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN universal.name IS 'A name of something like a person, entity, persona, etc.';

-- -----------------------------------------------------------------------------

-- TODO: Finish out this code to pull out parts of an email
-- NOTE: Only superuser can create a LEAKPROOF function
CREATE OR REPLACE FUNCTION universal.email_parts(
  IN p_email varchar(256)
)
RETURNS RECORD LANGUAGE sql STRICT IMMUTABLE PARALLEL RESTRICTED AS $$
  SELECT 1 AS result;
$$;
COMMENT ON FUNCTION universal.url_parts(varchar) IS 'pulls out parts of an email.';

DO $$ BEGIN
  CREATE DOMAIN universal.email AS varchar(256)
    CONSTRAINT email_parts_is_invalid
      CHECK (NOT universal.email_parts(VALUE) IS NULL);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN universal.email IS 'An email address.';

-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE DOMAIN universal.color_hex AS varchar(7)
  CONSTRAINT shared_color_hex_invalid_expected
    CHECK (VALUE ~ '^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN universal.color_hex IS 'An HTML hex color of format #rrggbb.';

-- -----------------------------------------------------------------------------

DO $$ BEGIN
  -- _ OR any letter (upper/lower) followed by _ - number or letter (upper/lower)
  CREATE DOMAIN universal.sql_identifier AS varchar(63)
    CHECK (VALUE ~ '^([^\W\d)]|[_])[\w_-]*$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN universal.sql_identifier IS 'Valid PostgreSql identifiers and key words (tables, columns, schema). Note: schema names can not start with pg_.';

DO $$ BEGIN
  CREATE DOMAIN universal.sql_identifier_lower AS varchar(63)
    CHECK (VALUE ~ '^([^\W\d)]|[_])[\w_-]*$' AND VALUE::text = lower(VALUE::text));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN universal.sql_identifier_lower IS 'Valid lower case PostgreSql identifiers and key words (tables, columns, schema). Note: schema names can not start with pg_.';


CREATE OR REPLACE FUNCTION universal.set_current_tenant(
  p_tenant_persona_id uuid
) RETURNS uuid AS
$$
DECLARE d_execute varchar;
BEGIN
  d_execute = FORMAT(
    'SET my.current_tentant_persona_id = ''%1$s'';',
    p_tenant_persona_id
  );
  EXECUTE (d_execute);
  RETURN p_tenant_persona_id;
END;
$$ LANGUAGE plpgsql STRICT PARALLEL RESTRICTED;
COMMENT ON FUNCTION universal.set_current_tenant(uuid) IS 'Sets the tenant persona id for the current session.';

-- ROLES -----------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE universal.role_table_policy(
  p_role_name universal.sql_identifier_lower,
  p_schema_name universal.sql_identifier_lower,
  p_table_name universal.sql_identifier_lower,
  p_policy varchar,
  p_revoke_columns varchar[]
)
LANGUAGE PLPGSQL AS $$
DECLARE d_grant_columns varchar;
DECLARE d_execute varchar;
BEGIN
  SELECT
    STRING_AGG(col.column_name, ',') INTO d_grant_columns
  FROM information_schema.columns AS col
  WHERE NOT col.column_name = ANY(p_revoke_columns)
  AND col.table_schema = p_schema_name
  AND col.table_name = p_table_name
  GROUP BY col.table_schema, col.table_name;

  d_execute = FORMAT('
      -- Revoke policy on the table because column permissions may have changed
      REVOKE %5$s ON TABLE %1$s.%2$s FROM %3$s;
      GRANT %5$s (%4$s) ON TABLE %1$s.%2$s TO %3$s;
      ', p_schema_name, p_table_name, p_role_name, d_grant_columns, p_policy
    );
  EXECUTE(d_execute);
END;
$$;
COMMENT ON PROCEDURE universal.role_table_policy IS
'Grant a given policy on a table for a given role. An optional list of columns can be provided whose access we will revoke.

EXAMPLE: call universal.role_table_policy(''accessor'', ''universal'', ''example'', ''INSERT'', [''created_at'']);

@role_name - The name of the role we will grant access to.
@schema_name - Name of schema the table is in.
@table_name - The name of the table.
@policy - The policy we are granting (SELECT, INSERT, UPDATE). NOTE: If you grant UPDATE then you must also grant SELECT. DELETE and TRUNCATE are not supported.
@revoke_columns - One or more columnns that will be revoked. For example, if the value is only [''created_at''] then all columns except created_at are granted.

NOTE: Postgreql provides a grant on a list of columnns but not a revoke on a list of columns.
';

-- https://www.postgresql.org/docs/current/sql-alterrole.html
CREATE OR REPLACE PROCEDURE universal.role_setup_login(
  p_role_name varchar
)
LANGUAGE PLPGSQL AS $$
DECLARE d_setting_name varchar;
DECLARE d_execute varchar;
DECLARE d_setting_password varchar;
BEGIN
  d_setting_name = FORMAT('my.roles.%1$s.password', p_role_name);

  d_setting_password = current_setting(d_setting_name, true);

  IF d_setting_password IS NULL OR d_setting_password = '' THEN
    d_execute = FORMAT ('
        ALTER ROLE %1$s WITH NOLOGIN;
        ALTER ROLE %1$s WITH PASSWORD NULL;
      ', p_role_name
    );
    RAISE WARNING 'removing login rights for user %', d_execute;
    EXECUTE (d_execute);
  ELSE
    d_execute = FORMAT ('
        ALTER ROLE %1$s WITH LOGIN;
        ALTER ROLE %1$s WITH PASSWORD ''%2$s'';
      ', p_role_name, d_setting_password
      );

    EXECUTE (d_execute);
  END IF;
END $$;


CREATE OR REPLACE PROCEDURE universal.role_create(
  p_role_name varchar,
  p_role_description varchar
) LANGUAGE PLPGSQL AS $$
DECLARE d_execute varchar;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_roles
    WHERE rolname = p_role_name
  ) THEN
    d_execute = FORMAT(
      'CREATE ROLE %1$s;',
      p_role_name
    );
    EXECUTE(d_execute);
  END IF;

  d_execute = FORMAT(
    'ALTER ROLE %1$s NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOLOGIN NOREPLICATION NOBYPASSRLS;',
    p_role_name, p_role_description
  );
  EXECUTE(d_execute);

  d_execute = FORMAT(
    'COMMENT ON ROLE %1$s IS ''%2$s'';',
    p_role_name, p_role_description
  );
  EXECUTE(d_execute);

  CALL universal.role_setup_login(p_role_name);
END $$;


-- Create rolls and set passwords -------------------------------------------

CALL universal.role_create(
  'mutator',
'A mutator is a general purpose role for selecting, inserting, updating and deleting data.
* Priviliges: SELECT, INSERT, UPDATE, DELETE
* Locked Columns: created_at, last_updated_at, table primary key id column.
'  
);


CALL universal.role_create(
  'importer',
'An importer is a general purpose role for importing data from an external data source.
* Priviliges: SELECT, INSERT, UPDATE, DELETE
* Locked Columns: none.
'  
);


CALL universal.role_create(
  'accessor',
'An accessor is a general purpose role for accessing data.
* Priviliges: SELECT
* Locked Columns: select only
'  
);

CALL universal.role_create(
  'manager',
'A manager is a general purpose role for selecting, inserting, updating and deleting data.
* Priviliges: SELECT, INSERT, UPDATE, DELETE
* Locked Columns: none
'  
);

-- -----------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE universal.role_setup(
  schema_name varchar,
  role_name varchar,
  privileges varchar = '' -- Examples are SELECT, UPDATE, DELETE, INSERT
)
LANGUAGE PLPGSQL AS $$
DECLARE schm record;
BEGIN
  EXECUTE(
    FORMAT('
      GRANT USAGE ON SCHEMA %1$s TO %2$s;
    ', schema_name, role_name)
  );

  IF (privileges = '') THEN
    EXECUTE(
      FORMAT('
        ALTER DEFAULT PRIVILEGES IN SCHEMA %1$s
          REVOKE ALL ON TABLES FROM %2$s;

        REVOKE ALL
        ON ALL TABLES IN SCHEMA %1$s
        FROM %2$s;

      ', schema_name, role_name)
    );
  ELSE
    EXECUTE(
      FORMAT('
        ALTER DEFAULT PRIVILEGES IN SCHEMA %1$s
          GRANT %3$s ON TABLES TO %2$s;

        GRANT %3$s
        ON ALL TABLES IN SCHEMA %1$s
        TO %2$s;
      ', schema_name, role_name, privileges)
    );
  END IF;
END;
$$;


CREATE OR REPLACE PROCEDURE universal.roles_setup(
  schema_name varchar
)
LANGUAGE PLPGSQL AS $$
DECLARE schm record;
BEGIN
  CALL universal.role_setup(schema_name, 'mutator', 'SELECT, UPDATE, DELETE, INSERT');
  CALL universal.role_setup(schema_name, 'importer', 'UPDATE, DELETE, INSERT');
  CALL universal.role_setup(schema_name, 'accessor', 'SELECT');
  CALL universal.role_setup(schema_name, 'manager', 'SELECT, UPDATE, DELETE, INSERT');
END;
$$;


-- SETUP ROLE FOR SCHEMA  ------------------------------------------------------

CALL universal.roles_setup('universal');

-- Test schema is defined before the roles so we setup role access here.
CALL universal.roles_setup('test');


-- FUNCTIONS -------------------------------------------------------------------

CREATE OR REPLACE FUNCTION universal.setting_boolean (
  p_setting text,
  p_default boolean = false,
  p_override_value boolean = null
)
RETURNS boolean LANGUAGE PLPGSQL IMMUTABLE PARALLEL RESTRICTED AS $$
DECLARE d_result boolean;
BEGIN
  IF NOT p_override_value IS NULL THEN
    RETURN p_override_value;
  END IF;

  WITH info AS (
    SELECT current_setting(p_setting, true) AS setting
  )
  SELECT 
    CASE WHEN info.setting IS NULL THEN
      p_default
    ELSE info.setting::boolean END INTO d_result
  FROM info;
  RETURN d_result;
END;
$$;
COMMENT ON FUNCTION universal.setting_boolean(text, boolean, boolean) IS
'Returns a current setting as a boolean value.

Example: SELECT universal.setting_boolean(''my.settings.multi_tenant'', true);

@setting - The name of the setting.
@default - The value to use if the setting is not found.
';

-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION universal.trigger_set_last_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_updated_at = CLOCK_TIMESTAMP();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION universal.trigger_set_last_updated_at() IS 'Used to set the last_updated_at column to now() on update. Also use this trigger for ON INSERT if you want to assure a user can not set their own last_updated_at.';

-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION universal.apply_table_settings(
  p_schema_name text,
  p_table_name text,
  p_override jsonb = '{
    "multi_tenant": null,
    "created_at_column": null,
    "last_updated_at_column": null
  }'::jsonb
)
RETURNS boolean LANGUAGE PLPGSQL STRICT VOLATILE PARALLEL RESTRICTED AS $$
DECLARE d_result boolean = true;
DECLARE d_updated_trigger_name universal.sql_identifier;
DECLARE d_execute varchar;
BEGIN
  IF universal.setting_boolean('my.settings.multi_tenant', false, (p_override->>'multi_tenant')::boolean) THEN
    EXECUTE (
      FORMAT('
      ALTER TABLE %1$s.%2$s
        ADD COLUMN IF NOT EXISTS tenant_persona_id uuid NOT NULL
          DEFAULT uuid_nil()
            REFERENCES persona.persona(persona_id);

        CREATE INDEX IF NOT EXISTS %1$s_%2$s_tenant_persona_id_idx
          ON %1$s.%2$s (tenant_persona_id);

        COMMENT ON COLUMN %1$s.%2$s.tenant_persona_id IS ''The active tenant of the entry used when a data system requires multi-tenant support.'';
     ', p_schema_name, p_table_name)
    );
  END IF;

  IF universal.setting_boolean('SET my.settings.multi_source', false, (p_override->>'multi_source')::boolean) THEN
    EXECUTE (
      FORMAT('
      ALTER TABLE %1$s.%2$s
        ADD COLUMN IF NOT EXISTS source_persona_id uuid NOT NULL
          DEFAULT uuid_nil()
            REFERENCES persona.persona(persona_id);

        CREATE INDEX IF NOT EXISTS %1$s_%2$s_source_persona_id_idx
          ON %1$s.%2$s (source_persona_id);

        COMMENT ON COLUMN %1$s.%2$s.source_persona_id IS ''The persona that was the source of the entry. A user for example OR imported data from a 3rd party. Also considered the source of truth for the entry.'';
     ', p_schema_name, p_table_name)
    );
  END IF;

  IF universal.setting_boolean('my.settings.created_at_column.add_to_table', false, (p_override->'created_at_column'->>'add_to_table')::boolean) THEN
    EXECUTE (
      FORMAT('
        ALTER TABLE %1$s.%2$s
          ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL
            DEFAULT CLOCK_TIMESTAMP();

        CREATE INDEX IF NOT EXISTS %1$s_%2$s_created_at_idx
          ON %1$s.%2$s (created_at);

        COMMENT ON COLUMN %1$s.%2$s.created_at IS ''The time (with timezone) the entry was added.'';
     ', p_schema_name, p_table_name)
    );

    -- TODO: Write loop to set roles based on universal settings
    -- SET my.settgins.last_updated_at_column.locked_roles=?????
    d_execute = FORMAT('
        CALL universal.role_table_policy(''mutator'', ''%1$s'', ''%2$s'', ''UPDATE'', ARRAY[''created_at'']);
        CALL universal.role_table_policy(''mutator'', ''%1$s'', ''%2$s'', ''INSERT'', ARRAY[''created_at'']);
     ', p_schema_name, p_table_name);

    EXECUTE (d_execute);

  END IF;

  IF universal.setting_boolean('my.settings.last_updated_at_column.add_to_table', false, (p_override->'last_updated_at_column'->>'add_to_table')::boolean) THEN
    EXECUTE (
      FORMAT('
        ALTER TABLE %1$s.%2$s
          ADD COLUMN IF NOT EXISTS last_updated_at timestamptz NOT NULL
            DEFAULT CLOCK_TIMESTAMP();

        CREATE INDEX IF NOT EXISTS %1$s_%2$s_last_updated_at_idx
          ON %1$s.%2$s (last_updated_at);

        COMMENT ON COLUMN %1$s.%2$s.last_updated_at IS ''The time (with timezone) the entry was last updated.'';
      ', p_schema_name, p_table_name)
    );

    d_updated_trigger_name = CONCAT(p_table_name, '_001_trigger_set_last_updated_at');

    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.triggers
      WHERE event_object_schema = p_schema_name AND event_object_table = p_table_name
      AND trigger_name = d_updated_trigger_name
    ) THEN
    EXECUTE (
      FORMAT('
        CREATE TRIGGER %3$s BEFORE UPDATE ON %1$s.%2$s
          FOR EACH ROW EXECUTE PROCEDURE universal.trigger_set_last_updated_at();
      ', p_schema_name, p_table_name, d_updated_trigger_name)
    ); 
    END IF;

  END IF;

  RETURN d_result;
END;
$$;


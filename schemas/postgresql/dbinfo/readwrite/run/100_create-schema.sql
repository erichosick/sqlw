/* Copyright (c) 2022 Eric Hosick All Rights Reserved */

-- SCHEMA ----------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS dbinfo;
COMMENT ON SCHEMA dbinfo IS 'contains general information about the database';

CALL universal.roles_setup('dbinfo');

CREATE OR REPLACE VIEW dbinfo.db_activity AS
SELECT
  psa.pid AS process_id,
  now() - psa.query_start AS duration,
  psa.query,
  psa.state
FROM pg_stat_activity AS psa
WHERE psa.state = 'active'
AND psa.query NOT ILIKE('%FROM dbinfo.db_activity%'); -- filter out this query
COMMENT ON VIEW dbinfo.db_activity IS 'Returns any active queries: ignoring the activity query itself.';

-- SELECT pg_cancel_backend();

CREATE OR REPLACE VIEW dbinfo.database_space_by_table AS
SELECT
  schemaname as table_schema,
  relname as table_name,
  pg_relation_size(relid) as data_size,
  pg_size_pretty(pg_relation_size(relid)) as data_size_pretty
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_relation_size(relid) desc;

/* Copyright (c) 2022 Eric Hosick All Rights Reserved */

-- -----------------------------------------------------------------------------
-- shared schema tests
-- -----------------------------------------------------------------------------


-- Setting Permissions

DO $$
DECLARE d_exception_thrown boolean = false;
BEGIN

  -- universal.url ----------------------------------------------------------------

  -- TODO: implement url validation code.
  PERFORM 'https:://www.derp.com'::universal.url;

  IF NOT EXISTS (
    SELECT 1
    WHERE 'https:://www.derp.com'::universal.url = 'HTTPS:://WWW.derp.com'::universal.url
  ) THEN
    RAISE EXCEPTION 'A url should be case-insensitive.';
  END IF;

  PERFORM test.it_should_exception('
    CREATE TABLE test.temp(rw universal.url);
    INSERT INTO test.temp VALUES (REPEAT(''-'', 2047 + 1));',
    'label should be limited to 2047 characters'
  );


  -- universal.label --------------------------------------------------------------
  PERFORM
    'valid label'::universal.label,
    'valid é%'::universal.label,
    ''::universal.label;

  PERFORM test.it_should_exception('
    CREATE TABLE test.temp(rw universal.label);
    INSERT INTO test.temp VALUES (REPEAT(''-'', 128 + 1));',
    'universal.label should be limited to 128 characters'
  );

  -- universal.label_short --------------------------------------------------------
  PERFORM
    'valid é%'::universal.label_short,
    ''::universal.label_short;

  PERFORM test.it_should_exception('
    CREATE TABLE test.temp(rw universal.label_short);
    INSERT INTO test.temp VALUES (REPEAT(''-'', 32 + 1));',
    'universal.label_short should be limited to 32 characters'
  );

  -- universal.title --------------------------------------------------------------
  PERFORM
    'valid é%'::universal.title,
    ''::universal.title;

  PERFORM test.it_should_exception('
    CREATE TABLE test.temp(rw universal.title);
    INSERT INTO test.temp VALUES (REPEAT(''-'', 128 + 1));',
    'universal.title should be limited to 128 characters'
  );

  -- universal.description --------------------------------------------------------
  PERFORM
    'valid é%'::universal.description,
    ''::universal.description;

  PERFORM test.it_should_exception('
    CREATE TABLE test.temp(rw universal.description);
    INSERT INTO test.temp VALUES (REPEAT(''-'', 4096 + 1));',
    'universal.description should be limited to 4096 characters'
  );

  -- universal.name ---------------------------------------------------------------
  PERFORM
    'valid é%'::universal.name,
    ''::universal.name;

  PERFORM test.it_should_exception('
    CREATE TABLE test.temp(rw universal.name);
    INSERT INTO test.temp VALUES (REPEAT(''-'', 512 + 1));',
    'universal.name should be limited to 512 characters'
  );

  -- universal.color_hex ---------------------------------------------------------------
  PERFORM
    '#fff'::universal.color_hex,
    '#aabbcc'::universal.color_hex,
    '#000000'::universal.color_hex;

  PERFORM test.it_should_exception(
    'SELECT ''Not a hex color''::universal.color_hex;',
    'color_hex should be a valid color described using hex'
  );

  CREATE TABLE universal.test_trigger (
    test_trigger_id int,
    info text,
    created_at timestamptz NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    last_updated_at timestamptz NOT NULL DEFAULT CLOCK_TIMESTAMP()
  );

  CREATE TRIGGER shared_test_trigger BEFORE UPDATE ON universal.test_trigger
    FOR EACH ROW EXECUTE PROCEDURE universal.trigger_set_last_updated_at();

  INSERT INTO universal.test_trigger(test_trigger_id, info)
  VALUES (1, 'first');

  -- NOTE: Heads up that the value for NOW is the same throughout a transaction
  -- which is why this test works.
  IF NOT EXISTS (
    SELECT 1 FROM universal.test_trigger
    WHERE
          test_trigger_id = 1
      AND info = 'first'
      AND created_at BETWEEN CLOCK_TIMESTAMP() - interval '.5 seconds' AND CLOCK_TIMESTAMP() + interval '.5 seconds'
      AND last_updated_at BETWEEN CLOCK_TIMESTAMP() - interval '.5 seconds' AND CLOCK_TIMESTAMP() + interval '.5 seconds'
  ) THEN
    RAISE EXCEPTION 'created_at and last_updated_at should be equal to CLOCK_TIMESTAMP()';
  END IF;

  INSERT INTO universal.test_trigger(test_trigger_id, info, last_updated_at)
  VALUES (2, 'second', '2022-08-09 00:00:00+00');
  
  IF NOT EXISTS (
    SELECT 1 FROM universal.test_trigger
    WHERE
          test_trigger_id = 2
      AND info = 'second'
      AND last_updated_at = '2022-08-09 00:00:00+00'
      AND created_at BETWEEN CLOCK_TIMESTAMP() - interval '.5 seconds' AND CLOCK_TIMESTAMP() + interval '.5 seconds'
  ) THEN
    RAISE EXCEPTION 'last_updated_at, when set by the user, should not default to CLOCK_TIMESTAMP()';
  END IF;

  INSERT INTO universal.test_trigger(test_trigger_id, info)
  VALUES (3, 'will overwrite');
  
  IF NOT EXISTS (
    SELECT 1 FROM universal.test_trigger
    WHERE
          test_trigger_id = 3
      AND info = 'will overwrite'
      AND created_at BETWEEN CLOCK_TIMESTAMP() - interval '.5 seconds' AND CLOCK_TIMESTAMP() + interval '.5 seconds'
      AND last_updated_at BETWEEN CLOCK_TIMESTAMP() - interval '.5 seconds' AND CLOCK_TIMESTAMP() + interval '.5 seconds'
  ) THEN
    RAISE EXCEPTION 'last_updated_at, when set to null by user, should be set to CLOCK_TIMESTAMP()';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM universal.test_trigger
    WHERE
          test_trigger_id = 3
      AND info = 'will overwrite'
      AND last_updated_at != CLOCK_TIMESTAMP()
      AND created_at != CLOCK_TIMESTAMP()
  ) THEN
    RAISE EXCEPTION 'CLOCK_TIMESTAMP(), after a COMMIT;, should have changed.';
  END IF;

  UPDATE universal.test_trigger
  SET info = 'overwritten'
  WHERE test_trigger_id = 3;

  IF NOT EXISTS (
    SELECT 1 FROM universal.test_trigger
    WHERE
          test_trigger_id = 3
      AND info = 'overwritten'
      AND last_updated_at BETWEEN CLOCK_TIMESTAMP() - interval '.5 seconds' AND CLOCK_TIMESTAMP() + interval '.5 seconds'
      AND created_at != CLOCK_TIMESTAMP()
  ) THEN
    RAISE EXCEPTION 'last_updated_at, after an update, should be CLOCK_TIMESTAMP() while crated at stays the same';
    -- NOTE: will get a deadlock if this test fails.
  END IF;

  ROLLBACK;


  -- Setting Permissions
  CREATE TABLE universal.test_role_policy (
    test_role_policy_id int,
    created_at timestamptz NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    last_updated_at timestamptz NOT NULL DEFAULT CLOCK_TIMESTAMP()
  );

  CREATE ROLE testrole;
  GRANT testrole TO postgres;
  GRANT USAGE ON SCHEMA universal TO testrole;
  GRANT USAGE ON SCHEMA test TO testrole;

  PERFORM test.it_should_exception('
    SET ROLE testrole;
    CREATE TABLE public.derp();
    ',
    'testrole should not be able to create a table in public because we ran REVOKE CREATE ON SCHEMA public FROM PUBLIC;'
  );

  PERFORM test.it_should_exception('
    SET ROLE testrole;
    SELECT * FROM universal.test_role_policy;
    ',
    'testrole, by default, should not have select permissions on test_role_policy table.'
  );
  
  PERFORM test.it_should_exception('
    SET ROLE testrole;
    INSERT INTO universal.test_role_policy (test_role_policy_id) VALUES(1);
    ',
    'testrole, by default, should not have insert permissions on test_role_policy table.'
  );

  PERFORM test.it_should_exception('
    SET ROLE testrole;
    UPDATE universal.test_role_policy SET test_role_policy_id = 1;
    ',
    'testrole, by default, should not have update permissions on test_role_policy table.'
  );

  PERFORM test.it_should_exception('
    SET ROLE testrole;
    DELETE FROM universal.test_role_policy;
    ',
    'testrole, by default, should not have update permissions on test_role_policy table.'
  );

  PERFORM test.it_should_exception('
    CALL universal.role_table_policy(''testrole'', ''universal'', ''test_role_policy'', ''DELETE'', ARRAY[''created_at'']);
    ',
    'policy should fail if DELETE is provided along with revoke columns.'
  );

  GRANT SELECT, DELETE ON universal.test_role_policy TO testrole;
  CALL universal.role_table_policy('testrole', 'universal', 'test_role_policy', 'UPDATE', ARRAY['created_at']);
  CALL universal.role_table_policy('testrole', 'universal', 'test_role_policy', 'INSERT', ARRAY['created_at']);

  -- NOTE: None of the following should error out as we've given testrole
  -- permission to 'SELECT', 'UPDATE', 'INSERT', 'DELETE'.
  SET ROLE testrole;
  INSERT INTO universal.test_role_policy (test_role_policy_id, last_updated_at)
  VALUES(1, CLOCK_TIMESTAMP());
  IF NOT EXISTS (
    SELECT 1
    FROM universal.test_role_policy
  ) THEN
    RAISE EXCEPTION 'testrole should be able to insert and select';
  END IF;

  UPDATE universal.test_role_policy
  SET
    test_role_policy_id = 1,
    last_updated_at = CLOCK_TIMESTAMP()
  WHERE test_role_policy_id = 1;

  DELETE FROM universal.test_role_policy
  WHERE test_role_policy_id = 1;

  SET ROLE postgres;

  PERFORM test.it_should_exception('
    SET ROLE testrole;
    INSERT INTO universal.test_role_policy (test_role_policy_id, created_at)
    VALUES(1, CLOCK_TIMESTAMP());
    ',
    'should not be able to insert with created_at provied'
  );

  PERFORM test.it_should_exception('
    SET ROLE testrole;
    UPDATE universal.test_role_policy
    SET created_at = CLOCK_TIMESTAMP()
    WHERE test_role_policy_id = 1;
    ',
    'should not be able to update created_at'
  );

  -- should be able to change the policy. Let's swap created_at and last_udpated_at
  CALL universal.role_table_policy('testrole', 'universal', 'test_role_policy', 'UPDATE', ARRAY['last_udpated_at']);
  CALL universal.role_table_policy('testrole', 'universal', 'test_role_policy', 'INSERT', ARRAY['last_udpated_at']);

  SET ROLE testrole;
  INSERT INTO universal.test_role_policy (test_role_policy_id, created_at)
  VALUES(1, CLOCK_TIMESTAMP());
  IF NOT EXISTS (
    SELECT 1
    FROM universal.test_role_policy
  ) THEN
    RAISE EXCEPTION 'testrole should be able to insert and select';
  END IF;

  UPDATE universal.test_role_policy
  SET
    test_role_policy_id = 1,
    created_at = CLOCK_TIMESTAMP()
  WHERE test_role_policy_id = 1;

  DELETE FROM universal.test_role_policy
  WHERE test_role_policy_id = 1;

  PERFORM test.it_should_exception('
    SET ROLE testrole;
    INSERT INTO universal.test_role_policy (test_role_policy_id, last_udpated_at)
    VALUES(1, CLOCK_TIMESTAMP());
    ',
    'should not be able to insert with last_udpated_at provied'
  );

  PERFORM test.it_should_exception('
    SET ROLE testrole;
    UPDATE universal.test_role_policy
    SET last_udpated_at = CLOCK_TIMESTAMP()
    WHERE test_role_policy_id = 1;
    ',
    'should not be able to update last_udpated_at'
  );

  ROLLBACK;
END;
$$;

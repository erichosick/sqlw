/* Copyright (c) 2022 Eric Hosick All Rights Reserved */

-- SCHEMA ----------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS test;
COMMENT ON SCHEMA test IS 'contains resources that can be used for testing';

-- FUNCTIONS -------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test.it_should_exception (
  p_sql_statement text,
  p_exception_message text
) RETURNS void LANGUAGE plpgsql AS
$$
DECLARE d_exception_thrown boolean = false;
BEGIN
  BEGIN
    EXECUTE p_sql_statement;
  EXCEPTION
    WHEN others THEN
      d_exception_thrown = true;
  END;

  IF d_exception_thrown = false THEN
    RAISE EXCEPTION '%', p_exception_message;
  END IF;
END;
$$;
COMMENT ON FUNCTION test.it_should_exception IS '
Executest the sql provided in p_sql_statement: expecting an exception of any kind to be thrown. The p_exception_message is displayed if no exceptoin is thrown.
';
 
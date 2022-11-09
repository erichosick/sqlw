/* Copyright (c) 2022 Eric Hosick All Rights Reserved */

-- SCHEMA ----------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS iso;
COMMENT ON SCHEMA iso IS 'contains iso data for languages, countries, etc. Date comes from places like https://datahub.io/collections/reference-data.';

CALL universal.roles_setup('iso');

-- DOMAINS ---------------------------------------------------------------------

DO $$ BEGIN
  CREATE DOMAIN iso.alpha2 AS CHAR(2)
    CONSTRAINT iso_alpha2_alpha_and_lower_case_only CHECK (VALUE::text = lower(VALUE::text) AND VALUE ~ '^[a-z]{2}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN iso.alpha2 IS 'Two character lower case alphabetical value.';

-- -----------------------------------------------------------------------------

DO $$ BEGIN
  CREATE DOMAIN iso.alpha3 AS CHAR(3)
    CONSTRAINT iso_alpha3_alpha_and_lower_case_only CHECK (VALUE::text = lower(VALUE::text) AND VALUE ~ '^[a-z]{3}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
COMMENT ON DOMAIN iso.alpha3 IS 'Three character lower case alphabetical value.';

-- TABLES ----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS iso.language_alpha2 (
  language_alpha2_id iso.alpha2 NOT NULL,
  label universal.label NOT NULL,
  CONSTRAINT country_alpha2_pkey PRIMARY KEY (language_alpha2_id),
  CONSTRAINT country_alpha2_label_key UNIQUE(label)
);

COMMENT ON TABLE iso.language_alpha2 IS 'ISO 639-1 two character langauge codes. Source Source https://datahub.io/core/language-codes#data-cli';
COMMENT ON COLUMN iso.language_alpha2.language_alpha2_id IS 'A unique 2 character id for the lanugage code as defined by the ISO 639 specification.';
COMMENT ON COLUMN iso.language_alpha2.label IS 'The english label of the alpha2 code as defined by the ISO 639 specification.';

SELECT universal.apply_table_settings('iso', 'language_alpha2', '{"multi_tenant": false}'::jsonb);

-- Setup how we will cluster the data for this table
ALTER TABLE iso.language_alpha2
  CLUSTER ON country_alpha2_pkey;

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS iso.country_alpha2 (
  country_alpha2_id iso.alpha2 NOT NULL,
  label universal.label NOT NULL,

  CONSTRAINT language_alpha2_pkey PRIMARY KEY (country_alpha2_id),
  CONSTRAINT language_alpha2_label_key UNIQUE(label)
);
COMMENT ON TABLE iso.country_alpha2 IS 'ISO 639-1 two character langauge codes. Source Source https://datahub.io/core/language-codes#data-cli';
COMMENT ON COLUMN iso.country_alpha2.country_alpha2_id IS 'A unique 2 character id for the lanugage code as defined by the ISO 639 specification.';
COMMENT ON COLUMN iso.country_alpha2.label IS 'The english label of the alpha2 code as defined by the ISO 639 specification.';

-- Setup how we will cluster the data for this table
ALTER TABLE iso.country_alpha2
  CLUSTER ON language_alpha2_pkey;

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS iso.currency_alpha3 (
  currency_alpha3_id iso.alpha3 NOT NULL,   
  currency universal.label NOT NULL,
  -- entity universal.name NOT NULL,
  numeric_code decimal(4,1) NULL,
  minor_unit int NOT NULL,
  withdrawal_date varchar(128) NULL,

  CONSTRAINT currency_alpha3_pkey PRIMARY KEY (currency_alpha3_id),
  CONSTRAINT currency_alpha3_currency_key UNIQUE(currency)
);
COMMENT ON TABLE iso.currency_alpha3 IS 'ISO 4217 currency codes. Source Source https://datahub.io/examples/example-sample-transform-on-currency-codes#data';
COMMENT ON COLUMN iso.currency_alpha3.currency_alpha3_id IS 'A unique 3 character id for the currency code as defined by the ISO 639 specification.';
COMMENT ON COLUMN iso.currency_alpha3.currency IS 'The english description of the currency defined by the ISO 4217 specification.';
-- COMMENT ON COLUMN iso.currency_alpha3.entity IS 'The english name of the entity (country for example) the currency is associated with as defined by the ISO 4217 specification.';
COMMENT ON COLUMN iso.currency_alpha3.minor_unit IS 'For a given curency, the precision of the minor unit of the currenct as defined by the ISO 4217 specification. The USD would be 2 as the minor unit of dollars are cents.';
COMMENT ON COLUMN iso.currency_alpha3.numeric_code IS 'The 3 digit numeric code of the currency is associated with as defined by the ISO 4217 specification.';
COMMENT ON COLUMN iso.currency_alpha3.withdrawal_date IS 'The date currency withdrawn (values can be ranges or months) as defined by the ISO 4217 specification. Null if currency has not yet been withdrawn.';

SELECT universal.apply_table_settings('iso', 'currency_alpha3', '{"multi_tenant": false}'::jsonb);

-- Setup how we will cluster the data for this table
ALTER TABLE iso.currency_alpha3
  CLUSTER ON currency_alpha3_pkey;

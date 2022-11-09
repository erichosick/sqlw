# Reusable Schema

The intent of this project is to provide well designed and re-usable database schema. Design considerations:

* support different database solutions ([Postgreql](https://postgresql.org/), [sqlite](https://www.sqlite.org/index.html), etc.)
* support differences in database schema between a readonly and readwrite database
* support testing
* idempotent sql
* no need to "undo" or rollback
* language and framework agnostic
* fully decoupled from any ORM
* define and support domains and business domains (invoices, people, etc.)
* support multiple/custom implementations of a given business domain
* extend existing schema.

## Execution Order

The order that schema are applied is based on the following order:

* `prerun` - all sql in `prerun` is executed based on package dependencies and then file name.
* `run` + `test` - all sql in `run` is executed based on package dependencies and then file name followed by any sql in the test directory.
* `postrun` - all sql in `postrun` is executed based on package dependencies and then file name.
* `seed` - all sql in `seed` is ran if that option is enabled
* `reset` - all sql in `reset` is ran, if that option is enabled, in the reverse order of dependencies.

## Directory Structure

Under the root of the project

* **schemas** - Contains all database schemas
  * **{database_platform}** - Database platform name. See DatabasePlatform type for details.
    * **{schema_name}** - The schema being defined. Preferably the directory name is the same as the schema name.
      * **readwrite** - database schema for master database (read/write).
        * **run** - core schema to run
        * **prerun** (optional) - schema to run before core schema in the `run` directory is ran.
        * **postrun** (optional) - schema to run after core schema in the `run` directory is ran.
        * **seed** (optional) - Any seed data that may be required for this database: not executed during testing. Seeds for test data should be within the test directory if needed.
        * **reset** (optional) - sql to run to reset the database to an original state. Not recommended as the sql schema should be idempotent.
        * **test** (optional) - sql to run when testing
      * **readonly** - database schema for the readonly database. Uses readwrite if no schema are provided?
        * **{see above directory structure}**

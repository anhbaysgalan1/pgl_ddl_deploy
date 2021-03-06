SET log_min_messages TO warning;
SET ROLE test_pgl_ddl_deploy;
CREATE SCHEMA foobar;

--This should never be allowed
\! PGOPTIONS='--client-min-messages=warning' psql -d contrib_regression  -c "CREATE TABLE foo(id int primary key); INSERT INTO foo (id) VALUES (1),(2),(3); DROP TABLE foo;"
\! PGOPTIONS='--client-min-messages=warning' psql -d contrib_regression  -c "CREATE TABLE foobar.foo(id int primary key); INSERT INTO foobar.foo (id) VALUES (1),(2),(3); DROP TABLE foobar.foo;"
SELECT set_name, ddl_sql_raw, ddl_sql_sent FROM pgl_ddl_deploy.events ORDER BY id DESC LIMIT 10;
SELECT set_name, ddl_sql_raw, command_tag, reason FROM pgl_ddl_deploy.unhandled ORDER BY id DESC LIMIT 10;

--This should be allowed by some configurations, and others not
\! PGOPTIONS='--client-min-messages=warning' psql -d contrib_regression  -c "BEGIN; CREATE TABLE foo(id int primary key); COMMIT;"
\! PGOPTIONS='--client-min-messages=warning' psql -d contrib_regression  -c "BEGIN; CREATE TABLE foobar.foo(id int primary key); COMMIT;"
SELECT set_name, ddl_sql_raw, ddl_sql_sent FROM pgl_ddl_deploy.events ORDER BY id DESC LIMIT 10;
SELECT set_name, ddl_sql_raw, command_tag, reason FROM pgl_ddl_deploy.unhandled ORDER BY id DESC LIMIT 10;

--Run all commands through cli to avoid permissions issues
\! PGOPTIONS='--client-min-messages=warning' psql -d contrib_regression  -c "DROP TABLE foo CASCADE;"
\! PGOPTIONS='--client-min-messages=warning' psql -d contrib_regression  -c "DROP TABLE foobar.foo CASCADE;"

--This should be allowed by some configurations, and others not
\! PGOPTIONS='--client-min-messages=warning' psql -d contrib_regression  -c "CREATE TABLE foo(id int primary key); DROP TABLE foo CASCADE;"
\! PGOPTIONS='--client-min-messages=warning' psql -d contrib_regression  -c "CREATE TABLE foobar.foo(id int primary key); DROP TABLE foobar.foo CASCADE;"
SELECT set_name, ddl_sql_raw, ddl_sql_sent FROM pgl_ddl_deploy.events ORDER BY id DESC LIMIT 10;
SELECT set_name, ddl_sql_raw, command_tag, reason FROM pgl_ddl_deploy.unhandled ORDER BY id DESC LIMIT 10;

\! PGOPTIONS='--client-min-messages=warning' psql -d contrib_regression  -c "CREATE TABLE foo(id int primary key);"
\! PGOPTIONS='--client-min-messages=warning' psql -d contrib_regression  -c "CREATE TABLE foobar.foo(id int primary key);"

--This should be allowed by some but not others
\! PGOPTIONS='--client-min-messages=warning' psql -d contrib_regression  -c "DROP TABLE foo, foobar.foo CASCADE;"
SELECT set_name, ddl_sql_raw, ddl_sql_sent FROM pgl_ddl_deploy.events ORDER BY id DESC LIMIT 10;
SELECT set_name, ddl_sql_raw, command_tag, reason FROM pgl_ddl_deploy.unhandled ORDER BY id DESC LIMIT 10;

--Resolutions
SELECT pgl_ddl_deploy.resolve_unhandled(id, 'DBA superhero deployed it manually on the subscribers!')
FROM pgl_ddl_deploy.unhandled;

--Test with no rows and a dummy row
SELECT pgl_ddl_deploy.resolve_exception(id, 'Mystery solved')
FROM pgl_ddl_deploy.exceptions;

BEGIN;
INSERT INTO pgl_ddl_deploy.exceptions (set_name) VALUES ('test1');

SELECT pgl_ddl_deploy.resolve_exception(id, 'Mystery solved')
FROM pgl_ddl_deploy.exceptions;
ROLLBACK;

SELECT resolved, resolved_notes, set_name, ddl_sql_raw, command_tag, reason FROM pgl_ddl_deploy.unhandled ORDER BY id DESC LIMIT 10;

SELECT * FROM pgl_ddl_deploy.exceptions;

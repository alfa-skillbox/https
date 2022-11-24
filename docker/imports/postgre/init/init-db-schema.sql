CREATE SCHEMA IF NOT EXISTS https_server_schema AUTHORIZATION postgres;

GRANT ALL ON SCHEMA https_server_schema TO postgres;

ALTER DEFAULT PRIVILEGES IN SCHEMA https_server_schema
GRANT ALL ON TABLES TO postgres WITH GRANT OPTION;

ALTER DEFAULT PRIVILEGES IN SCHEMA https_server_schema
GRANT SELECT, USAGE ON SEQUENCES TO postgres WITH GRANT OPTION;

ALTER DEFAULT PRIVILEGES IN SCHEMA https_server_schema
GRANT EXECUTE ON FUNCTIONS TO postgres WITH GRANT OPTION;

ALTER DEFAULT PRIVILEGES IN SCHEMA https_server_schema
GRANT USAGE ON TYPES TO postgres WITH GRANT OPTION;

-- Table: users

CREATE TABLE IF NOT EXISTS https_server_schema.jsons (
  id bigserial NOT NULL UNIQUE PRIMARY KEY,
  json jsonb NOT NULL
);

ALTER TABLE https_server_schema.jsons
    OWNER to postgres;
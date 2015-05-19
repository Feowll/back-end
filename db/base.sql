-- This is for PostGresQL
-- We intentionaly make this quite abstract so that it can be reused in
-- other contexts after Feowl.

CREATE TABLE users (
  -- Both xid and phone are actually only hashes of the real thing.
  xid               char(32) UNIQUE NULL,
  phone             char(32) UNIQUE NULL,
  default_location  text NULL,
  last_active       timestamp(0) NOT NULL default now(),
  verification_code varchar(8) NULL
) WITH (OIDS=FALSE);

CREATE UNIQUE INDEX users_xid ON users (xid) WHERE xid IS NOT NULL;
CREATE UNIQUE INDEX users_phone ON users (phone) WHERE phone IS NOT NULL;

CREATE TABLE events (
  location           text NULL,
  reported_by_xid    char(32) NULL REFERENCES users (xid)   ON DELETE CASCADE ON UPDATE NO ACTION,
  reported_by_phone  char(32) NULL REFERENCES users (phone) ON DELETE CASCADE ON UPDATE NO ACTION,
  CHECK (reported_by_xid IS NULL <> reported_by_phone IS NULL),
  start              timestamp(0) NOT NULL default now(),
  duration           interval(0) NULL,
  comment            char(32) NULL
) WITH (OIDS=FALSE);

CREATE INDEX events_start ON events (start);
CREATE INDEX events_duration ON events (duration);


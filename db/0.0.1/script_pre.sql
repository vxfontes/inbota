-- Pre-migration for v0.0.1 (beta)
-- Creates extensions/schemas needed before tables.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Base schema namespace (optional)
CREATE SCHEMA IF NOT EXISTS inbota;

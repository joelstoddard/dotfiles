---
paths:
  - "**/migrations/**"
  - "**/migrate/**"
  - "**/alembic/**"
  - "**/*.sql"
---
# Schema change and migrations

## Schema change
*Tier: CHANGE*

* ALWAYS manage schema changes as versioned, reviewed, automated migrations in version control.
* NEVER make manual changes to a production schema.
* ALWAYS make migrations backward-compatible (expand, migrate, THEN contract) so deploys and rollbacks are safe in both directions.
* NEVER take a long lock on a hot table. ALWAYS use online, batched migrations for large tables.
* NEVER run destructive statements (DROP, TRUNCATE, unbounded DELETE/UPDATE) against any shared or production database without explicit approval.

## Migration & Data Testing
*Tier: CHANGE (production-shaped data: RELEASE)*

* ALWAYS test EVERY schema migration forwards AND backwards against realistic data volumes.
* ALWAYS test migrations against production-shaped data BEFORE they are proposed for production.
* ALWAYS validate data integrity (counts, checksums, constraints) before AND after a migration.
* NEVER run a migration against production data yourself without explicit approval.

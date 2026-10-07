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

* You MUST manage schema changes as versioned, reviewed, automated migrations in version control.
* You MUST NOT make manual changes to a production schema.
* You MUST make migrations backward-compatible (expand, migrate, THEN contract) so deploys and rollbacks are safe in both directions.
* You MUST NOT take a long lock on a hot table. You MUST use online, batched migrations for large tables.
* You MUST NOT run destructive statements (DROP, TRUNCATE, unbounded DELETE/UPDATE) against any shared or production database without explicit approval.

## Migration & Data Testing
*Tier: CHANGE (production-shaped data: RELEASE)*

* You MUST test EVERY schema migration forwards AND backwards against realistic data volumes.
* You MUST test migrations against production-shaped data BEFORE they are proposed for production.
* You MUST validate data integrity (counts, checksums, constraints) before AND after a migration.
* You MUST NOT run a migration against production data yourself without explicit approval.

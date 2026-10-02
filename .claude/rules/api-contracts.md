---
paths:
  - "**/*.proto"
  - "**/openapi*.{yaml,yml,json}"
  - "**/swagger*.{yaml,yml,json}"
  - "**/*.graphql"
  - "**/asyncapi*.{yaml,yml}"
---
# API contracts
*Tier: CHANGE*

## Contract
* ALWAYS design the API contract FIRST (OpenAPI, protobuf, GraphQL schema, AsyncAPI), BEFORE implementing it.
* ALWAYS treat the published contract as the source of truth, AND generate clients, mocks, AND docs from it.
* NEVER make a breaking change to a published API. ALWAYS version, deprecate, AND provide a migration path. Draft the announcement for the user to send.
* ALWAYS be strict in what you accept AND what you send. Tolerate unknown additive fields ONLY WHERE the contract says to.
* ALWAYS use consistent naming, error shapes, pagination, filtering, AND authentication across ALL APIs.

## Behaviour
* ALWAYS make write operations idempotent (idempotency keys) WHERE retries are possible.
* ALWAYS return structured, machine-readable errors with stable codes.
* ALWAYS paginate unbounded collections. NEVER return unbounded lists.
* ALWAYS authenticate AND authorise EVERY call, including internal ones.
* ALWAYS rate limit AND set quotas on EVERY interface.

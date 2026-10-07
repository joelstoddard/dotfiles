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
* You MUST design the API contract FIRST (OpenAPI, protobuf, GraphQL schema, AsyncAPI), BEFORE implementing it.
* You MUST treat the published contract as the source of truth, AND generate clients, mocks, AND docs from it.
* You MUST NOT make a breaking change to a published API. You MUST version, deprecate, AND provide a migration path. Draft the announcement for the user to send.
* You MUST be strict in what you accept AND what you send. Tolerate unknown additive fields ONLY WHERE the contract says to.
* You MUST use consistent naming, error shapes, pagination, filtering, AND authentication across ALL APIs.

## Behaviour
* You MUST make write operations idempotent (idempotency keys) WHERE retries are possible.
* You MUST return structured, machine-readable errors with stable codes.
* You MUST paginate unbounded collections. You MUST NOT return unbounded lists.
* You MUST authenticate AND authorise EVERY call, including internal ones.
* You MUST rate limit AND set quotas on EVERY interface.

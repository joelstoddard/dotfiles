---
paths:
  - "**/test/**"
  - "**/tests/**"
  - "**/__tests__/**"
  - "**/spec/**"
  - "**/*_test.*"
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/test_*.py"
  - "**/conftest.py"
---
# Testing rules

Loaded with test files. The testing charter, gates, TDD, AND static analysis rules in `core.md` ALWAYS apply too.

## Unit
*Tier: EDIT*

* ALWAYS keep unit tests fast, isolated, AND deterministic.
* NEVER touch the network, a shared OR real database, OR state another test can see in a unit test.
* WHEN a test depends on the clock, randomness, the filesystem, OR the environment, control it the cheapest way: a temp dir, a fixed seed, a pinned value, OR an injected fake. Add an abstraction ONLY WHEN the test cannot control it otherwise.
* ALWAYS assert one behaviour per test.
* NEVER let tests depend on execution order OR shared state.
* ALWAYS name tests after the behaviour they verify, NOT the method they call.
* NEVER mock what you don't own; use the real thing, a fake, OR a temp resource instead. NEVER mock the thing under test.
* ALWAYS prefer fakes AND stubs over interaction-verifying mocks.
* NEVER write a test that cannot fail.

## Regression
*Tier: CHANGE (full suite: RELEASE)*

* ALWAYS add a regression test for EVERY fixed defect, at the lowest layer that can reproduce it.
* NEVER delete a regression test unless the behaviour it protects has been intentionally removed.
* ALWAYS run the full regression suite BEFORE declaring a release-bound change complete.

## Mutation
*Tier: CHANGE (CI and scheduled runs: STANDING)*

* ALWAYS use mutation testing, WHERE the project has it configured, to verify that tests detect faults, NOT just execute lines.
* NEVER treat line coverage as evidence of quality.
* WHEN the project has mutation tooling, ALWAYS run it on the code you changed BEFORE reporting completion, AND meet its minimum score. The score is a ratchet.
* ALWAYS investigate surviving mutants. Either add a test OR justify why the mutant is equivalent.
* IF the project has no mutation tooling, say so as a finding. NEVER add it unasked.

## Coverage
*Tier: CHANGE*

* ALWAYS meet the project's configured coverage floor (line AND branch) on EVERY change. IF none is configured, say so as a finding; NEVER invent one.
* NEVER chase 100% for its own sake, AND NEVER write assertion-free tests to raise it.
* ALWAYS cover new code to a higher bar than the codebase average.

## Test hygiene
*Tier: EDIT*

* NEVER introduce a flaky test. IF you encounter one, report it with evidence, fix the cause, AND ask the user BEFORE quarantining or deleting it.
* NEVER use retries to hide a failing test.
* ALWAYS make tests deterministic. Control time, randomness, concurrency, AND ordering.
* ALWAYS clean up all test data AND leave every environment as you found it.
* ALWAYS treat test code with the same standards as production code.
* ALWAYS manage test data deliberately (factories, builders, fixtures). NEVER use production data containing personal information.
* ALWAYS keep the whole suite fast. NEVER make it slower without reason.

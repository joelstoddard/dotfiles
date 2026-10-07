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

Loaded with test files. The testing charter, gates, TDD, AND static analysis rules in the core principles always apply too.

## Unit
*Tier: EDIT*

* You MUST keep unit tests fast, isolated, AND deterministic.
* You MUST NOT touch the network, a shared OR real database, OR state another test can see in a unit test.
* WHEN a test depends on the clock, randomness, the filesystem, OR the environment, control it the cheapest way: a temp dir, a fixed seed, a pinned value, OR an injected fake. Add an abstraction ONLY WHEN the test cannot control it otherwise.
* You MUST assert one behaviour per test.
* You MUST NOT let tests depend on execution order OR shared state.
* You MUST name tests after the behaviour they verify, NOT the method they call.
* You MUST NOT mock what you don't own; use the real thing, a fake, OR a temp resource instead. You MUST NOT mock the thing under test.
* You SHOULD prefer fakes AND stubs over interaction-verifying mocks.
* You MUST NOT write a test that cannot fail.

## Regression
*Tier: CHANGE (full suite: RELEASE)*

* You MUST add a regression test for EVERY fixed defect, at the lowest layer that can reproduce it.
* You MUST NOT delete a regression test unless the behaviour it protects has been intentionally removed.
* You MUST run the full regression suite BEFORE declaring a release-bound change complete.

## Mutation
*Tier: CHANGE (CI and scheduled runs: STANDING)*

* You MUST use mutation testing, WHERE the project has it configured, to verify that tests detect faults, NOT just execute lines.
* You MUST NOT treat line coverage as evidence of quality.
* WHEN the project has mutation tooling, you MUST run it on the code you changed BEFORE reporting completion, AND meet its minimum score. The score is a ratchet.
* You MUST investigate surviving mutants. Either add a test OR justify why the mutant is equivalent.
* IF the project has no mutation tooling, say so as a finding. You MUST NOT add it unasked.

## Coverage
*Tier: CHANGE*

* You MUST meet the project's configured coverage floor (line AND branch) on EVERY change. IF none is configured, say so as a finding; you MUST NOT invent one.
* You MUST NOT chase 100% for its own sake, AND you MUST NOT write assertion-free tests to raise it.
* You MUST cover new code to a higher bar than the codebase average.

## Test hygiene
*Tier: EDIT*

* You MUST NOT introduce a flaky test. IF you encounter one, report it with evidence, fix the cause, AND ask the user BEFORE quarantining or deleting it.
* You MUST NOT use retries to hide a failing test.
* You MUST make tests deterministic. Control time, randomness, concurrency, AND ordering.
* You MUST clean up all test data AND leave every environment as you found it.
* You MUST treat test code with the same standards as production code.
* You MUST manage test data deliberately (factories, builders, fixtures). You MUST NOT use production data containing personal information.
* You MUST keep the whole suite fast. You SHOULD NOT make it slower.

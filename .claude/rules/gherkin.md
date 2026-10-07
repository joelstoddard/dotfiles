---
paths:
  - "**/*.feature"
---
# Gherkin
*Tier: CHANGE*

* You MUST write scenarios in business language. You MUST NOT reference UI elements, selectors, endpoints, OR database tables.
* You MUST write declarative steps (what); you MUST NOT write imperative steps (how).
* You MUST limit a scenario to ONE behaviour AND ONE `When`.
* You MUST keep `Given` to state, `When` to action, `Then` to observable outcome.
* You MUST NOT assert internal state in a `Then`. ONLY assert what a user or consumer could observe.
* You MUST NOT make scenarios depend on one another. Each MUST set up its own state.
* You MUST use `Scenario Outline` for the same behaviour across varied data, AND you MUST NOT use it for different behaviours.
* You MUST keep `Background` short and relevant to EVERY scenario in the feature.
* You MUST write steps so they are reusable. You MUST NOT write a step that only one scenario can use.
* You MUST reuse the project's existing step vocabulary BEFORE inventing new steps.
* You MUST write the scenario BEFORE the implementation, in the stakeholder's language.
* You MUST NOT use Gherkin for what a unit test covers better.

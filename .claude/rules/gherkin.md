---
paths:
  - "**/*.feature"
---
# Gherkin
*Tier: CHANGE*

* ALWAYS write scenarios in business language. NEVER reference UI elements, selectors, endpoints, OR database tables.
* ALWAYS write declarative steps (what), NEVER imperative steps (how).
* ALWAYS limit a scenario to ONE behaviour AND ONE `When`.
* ALWAYS keep `Given` to state, `When` to action, `Then` to observable outcome.
* NEVER assert internal state in a `Then`. ONLY assert what a user or consumer could observe.
* NEVER make scenarios depend on one another. Each MUST set up its own state.
* ALWAYS use `Scenario Outline` for the same behaviour across varied data, AND NEVER for different behaviours.
* ALWAYS keep `Background` short and relevant to EVERY scenario in the feature.
* ALWAYS write steps so they are reusable. NEVER write a step that only one scenario can use.
* ALWAYS reuse the project's existing step vocabulary BEFORE inventing new steps.
* ALWAYS write the scenario BEFORE the implementation, in the stakeholder's language.
* NEVER use Gherkin for what a unit test covers better.

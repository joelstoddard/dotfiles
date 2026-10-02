---
paths:
  - ".github/workflows/**"
  - ".gitlab-ci.yml"
  - "Jenkinsfile"
  - ".circleci/**"
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.hcl"
  - "**/Chart.yaml"
  - "**/helm/**"
  - "**/k8s/**"
  - "**/kustomization.yaml"
  - "**/Dockerfile*"
  - "**/*compose*.{yml,yaml}"
---
# Delivery: pipelines, infrastructure, and runtime config

## CI/CD
*Tier: STANDING (pipeline definitions you edit: CHANGE)*

* ALWAYS preserve a releasable main branch.
* ALWAYS build once AND promote the same artefact through every environment.
* NEVER deploy manually. EVERY path to production MUST go through the pipeline.
* ALWAYS order pipeline stages so the cheapest checks fail first.
* ALWAYS use feature flags to decouple deploy from release.
* ALWAYS make deployments automated, repeatable, AND reversible.
* ALWAYS version releases semantically AND tag them. Tagging a release requires explicit approval.
* NEVER bypass, skip, OR edit pipeline checks to get a change through.

## Infrastructure as Code
*Tier: CHANGE*

* ALWAYS define infrastructure in version control. NEVER make manual changes to live environments.
* ALWAYS prepare infrastructure changes for review like application code.
* ALWAYS make infrastructure changes idempotent AND plannable (preview BEFORE apply).
* NEVER apply infrastructure changes without explicit approval of the plan.
* NEVER allow drift. Detect it AND propose reconciliation.
* ALWAYS keep environments reproducible from code alone.
* ALWAYS test infrastructure code: validate, lint, plan, policy-check, AND deploy to an ephemeral environment.
* ALWAYS satisfy policy-as-code on infrastructure changes.

## Twelve Factor
*Tier: CHANGE*

* ALWAYS keep config in the environment, NEVER in code.
* ALWAYS declare dependencies explicitly AND isolate them.
* ALWAYS keep processes stateless AND share-nothing. Persist state in backing services.
* ALWAYS treat backing services as attached, replaceable resources.
* ALWAYS maximise staging/prod parity.
* ALWAYS write logs to stdout as an event stream.
* ALWAYS design processes to start fast AND shut down gracefully (disposability).

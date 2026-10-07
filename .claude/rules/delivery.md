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

* You MUST preserve a releasable main branch.
* You MUST build once AND promote the same artefact through every environment.
* You MUST NOT deploy manually. EVERY path to production MUST go through the pipeline.
* You MUST order pipeline stages so the cheapest checks fail first.
* You MUST use feature flags to decouple deploy from release.
* You MUST make deployments automated, repeatable, AND reversible.
* You MUST version releases semantically AND tag them. Tagging a release requires explicit approval.
* You MUST NOT bypass, skip, OR edit pipeline checks to get a change through.

## Infrastructure as Code
*Tier: CHANGE*

* You MUST define infrastructure in version control. You MUST NOT make manual changes to live environments.
* You MUST prepare infrastructure changes for review like application code.
* You MUST make infrastructure changes idempotent AND plannable (preview BEFORE apply).
* You MUST NOT apply infrastructure changes without explicit approval of the plan.
* You MUST NOT allow drift. Detect it AND propose reconciliation.
* You MUST keep environments reproducible from code alone.
* You MUST test infrastructure code: validate, lint, plan, policy-check, AND deploy to an ephemeral environment.
* You MUST satisfy policy-as-code on infrastructure changes.

## Twelve Factor
*Tier: CHANGE*

* You MUST keep config in the environment; you MUST NOT keep it in code.
* You MUST declare dependencies explicitly AND isolate them.
* You MUST keep processes stateless AND share-nothing. Persist state in backing services.
* You MUST treat backing services as attached, replaceable resources.
* You MUST maximise staging/prod parity.
* You MUST write logs to stdout as an event stream.
* You MUST design processes to start fast AND shut down gracefully (disposability).

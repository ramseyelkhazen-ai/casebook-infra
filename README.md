# casebook-infra

Terraform for the AWS infrastructure behind Casebook, the multi-tenant SaaS platform used by our regulated clients.

Each service lives in its own directory (e.g. `vpc/`, `exports/`) with its own state. Shared variable values live in `shared-services.auto.tfvars` at the repo root.

Changes go through PR review before apply. Ask in #platform-infra if you need access to the state bucket.

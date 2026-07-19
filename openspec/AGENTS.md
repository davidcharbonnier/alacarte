# openspec — Specs & Change Management

## Purpose

OpenSpec-based specification and change management for the À la carte project. Tracks feature specs, active changes, and archived change history.

## Ownership

- All files under `openspec/`

## Local Contracts

- `config.yaml`: Project context and rules (spec-driven schema)
- `specs/`: Mainline specs — the current truth for implemented features (one folder per capability, not individually indexed)
- `changes/`: Active change proposals in progress
  - `refactor-ci-cd-pipeline/`: CI/CD pipeline refactoring
  - `postgres-migration/`: MySQL → Postgres (Neon) migration with pgloader data move
- `changes/archive/`: Completed changes, date-prefixed (not individually indexed)
- Each change has: `proposal.md`, `tasks.md`, optional `design.md`
- Delta specs in `changes/{name}/specs/` are merged into main `specs/` on completion

## Work Guidance

- New changes start via CLI: `openspec new change <name>`, then `openspec status` / `openspec instructions <artifact>` drive the workflow
- Artifact order: proposal → design → specs → tasks → implementation
- Delta specs in active changes should be synced to main specs when change completes
- Archive completed changes to `changes/archive/` with date prefix
- Specs use `## ADDED|MODIFIED|REMOVED Requirements` headers for delta diffs

## Verification

- `openspec validate --changes` — validates change structure and spec format

## Child DOX Index

No children. Flat structure under `openspec/`.
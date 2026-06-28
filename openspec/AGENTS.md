# openspec — Specs & Change Management

## Purpose

OpenSpec-based specification and change management for the À la carte project. Tracks feature specs, active changes, and archived change history.

## Ownership

- All files under `openspec/`

## Local Contracts

- `config.yaml`: Project context and rules (spec-driven schema)
- `specs/`: Mainline specs — the current truth for implemented features
  - `item-management/spec.md`, `chili-sauce-management/spec.md`
- `changes/`: Active change proposals in progress
  - `dynamic-item-schema/`: Dynamic schema system (design, proposal, tasks, delta specs)
  - `refactor-ci-cd-pipeline/`: CI/CD pipeline refactoring
- `changes/archive/`: Completed/historical changes
  - `2026-01-19-add-item-picture-filter/`
  - `2026-02-04-add-chili-sauce-itemtype/`
- Each change has: `proposal.md`, `tasks.md`, optional `design.md`
- Delta specs in `changes/{name}/specs/` are merged into main `specs/` on completion

## Work Guidance

- New changes follow OpenSpec workflow: proposal → design → tasks → implementation
- Delta specs in active changes should be synced to main specs when change completes
- Archive completed changes to `changes/archive/` with date prefix
- Specs use `## ADDED|MODIFIED|REMOVED Requirements` headers for delta diffs

## Verification

- No automated spec verification configured

## Child DOX Index

No children. Flat structure under `openspec/`.
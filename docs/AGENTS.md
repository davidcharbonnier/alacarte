# docs — Centralized Documentation

## Purpose

Central documentation hub for the À la carte monorepo. Organized by purpose rather than by app. Covers cross-app features, app-specific details, architecture, operations, and contributor guides.

## Ownership

- All `docs/` markdown files
- Documentation is the source of truth for feature behavior and architecture

## Local Contracts

- Organization by purpose: `features/`, `architecture/`, `api/`, `client/`, `admin/`, `guides/`, `getting-started/`, `operations/`
- Cross-app feature docs (`features/`) describe behavior spanning all three apps
- App-specific docs (`api/`, `client/`, `admin/`) contain implementation details
- Each subdirectory has a README.md hub page
- Quick-start instructions live in each app's own README (`apps/*/README.md`), not here
- Guides (`guides/`) are task-oriented walkthroughs
- Operations (`operations/`) cover CI/CD, deployment, secrets

## Work Guidance

- When adding features or changing behavior, update relevant docs in `docs/`
- Cross-reference related docs; use relative links
- Keep docs concise and actionable
- Follow existing structure: purpose-first organization
- When adding new docs, update the hub README (`docs/README.md`) with a new navigation entry

## Verification

- No automated verification configured
- Manual review: doc links resolve, examples are current, structure follows conventions

## Child DOX Index

No children. Flat docs under `docs/`; subdirectories are organizational only.
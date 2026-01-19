# Proposal: Add Chili Sauce Item Type

## Overview

Add "chili sauce" as a new consumable item type to the À la carte platform. Chili sauce will follow the same architectural patterns as existing item types (cheese, gin, wine, coffee) with full support for:

- Backend API with CRUD operations and admin endpoints
- Frontend Flutter client with forms, filtering, and localization
- Admin panel with config-driven management
- Rating system integration (automatic)
- Privacy settings integration (automatic)
- Image upload support

## Motivation

Chili sauce is a popular consumable category that users want to rate and share. Adding this item type expands the platform's coverage and provides value to users interested in spicy condiments.

## Goals

1. **Backend**: Create complete API endpoints for chili sauce management
2. **Frontend**: Implement full UI support with forms and filtering
3. **Admin**: Add config-driven management interface
4. **Integration**: Leverage existing rating and privacy systems (automatic)

## Non-Goals

- Changing existing item type implementations
- Modifying the rating system architecture
- Altering the privacy model
- Adding new features beyond standard item type capabilities

## Success Criteria

- Users can create, view, edit, and delete chili sauces
- Chili sauces can be rated and shared (automatic via existing systems)
- Admin panel can manage chili sauces (list, detail, delete, seed)
- Image upload works for chili sauces
- Search and filtering work across all chili sauce attributes
- French and English localization complete
- All tests pass

## Scope

### In Scope

- Backend: Model, controller, routes, migrations, seeding
- Frontend: Model, service, provider, form strategy, localization
- Admin: Config entry, color definition
- Documentation: Update guides and checklists

### Out of Scope

- New rating features
- Privacy model changes
- Database schema changes beyond chili sauce table
- New UI patterns or components

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Incorrect spice level representation | Use select dropdown with predefined levels (Mild, Medium, Hot, Extra Hot, Extreme) |
| Chili list complexity | Store as comma-separated text (like coffee tasting notes) for simplicity |
| Naming inconsistency | Use "chili-sauce" in code, "Chili Sauce" in UI |

## Dependencies

- Existing item type infrastructure (cheese, gin, wine, coffee)
- Generic rating and privacy systems
- Admin panel config-driven architecture

## Alternatives Considered

1. **Multiple chili types (sauce, powder, fresh)**: Rejected - too complex for initial implementation
2. **Custom spice level scale (1-10)**: Rejected - predefined levels match existing patterns (select dropdowns)
3. **Separate chili table**: Rejected - comma-separated text is simpler and sufficient

## Implementation Timeline

Estimated: ~2 hours (Backend: 65 min | Frontend: 50 min | Admin: 5 min)

## Related Changes

None - this is a standalone feature addition

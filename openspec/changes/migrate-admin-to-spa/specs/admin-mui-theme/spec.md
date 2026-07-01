## ADDED Requirements

### Requirement: M3 tonal palette from seed color

The admin panel SHALL use a Material Design 3 color scheme derived from the deepPurple seed color, matching the Flutter client's `ColorScheme.fromSeed(Colors.deepPurple)`.

#### Scenario: Light mode colors

- **WHEN** the admin panel renders in light mode
- **THEN** the primary color SHALL be derived from `#673AB7` (deepPurple)
- **AND** the color scheme SHALL include generated tonal palette roles (primary, onPrimary, primaryContainer, secondary, tertiary, surface, error)

#### Scenario: Dark mode colors

- **WHEN** the admin panel renders in dark mode
- **THEN** the primary color SHALL be the dark variant derived from `#673AB7` (deepPurple)
- **AND** surface and background colors SHALL be appropriate for dark viewing

### Requirement: Light and dark mode support

The admin panel SHALL support both light and dark color schemes, toggled via a `.light` or `.dark` CSS class on the `<html>` element.

#### Scenario: User toggles dark mode

- **WHEN** the user clicks the theme toggle in the header
- **AND** the current theme is light
- **THEN** the `<html>` element SHALL have the `.dark` class applied
- **AND** all MUI components SHALL render with dark color scheme tokens
- **AND** the preference SHALL be persisted to `localStorage`

#### Scenario: User toggles light mode

- **WHEN** the user clicks the theme toggle in the header
- **AND** the current theme is dark
- **THEN** the `<html>` element SHALL have the `.light` class applied
- **AND** all MUI components SHALL render with light color scheme tokens
- **AND** the preference SHALL be persisted to `localStorage`

#### Scenario: Respect system preference on first visit

- **WHEN** a user visits the admin panel for the first time (no saved preference)
- **THEN** the color scheme SHALL match the operating system's `prefers-color-scheme` setting

#### Scenario: Session persistence

- **WHEN** a user has previously selected a theme
- **AND** the preference is stored in `localStorage`
- **THEN** the admin panel SHALL apply the saved theme on page load without a flash of wrong theme

### Requirement: Design token parity with Flutter client

The admin panel SHALL use the same spacing, border radius, and accent color scales as the Flutter client.

#### Scenario: Spacing scale

- **WHEN** MUI components use spacing values
- **THEN** the base spacing unit SHALL be 8px
- **AND** common spacing values SHALL be multiples of 8px (8, 16, 24, 32, 48)

#### Scenario: Border radius scale

- **WHEN** MUI components render with border radius
- **THEN** the default border radius SHALL be 8px
- **AND** available radius values SHALL include 2px, 4px, 8px, 12px, and 16px

#### Scenario: Typography scale

- **WHEN** text is rendered in the admin panel
- **THEN** the font family SHALL be Roboto (matching Flutter default)
- **AND** font sizes SHALL follow the M3 type scale (display, headline, title, body, label)

### Requirement: Item-type accent colors are schema-driven

The admin panel SHALL read item-type accent colors from the schema's `color` field at render time, rather than maintaining a hardcoded per-type color map. This makes the schema registry the single source of truth for item-type colors and avoids drift when new item types are added via the schema editor.

#### Scenario: Item type with a schema color

- **WHEN** components render item-type UI (badges, card accents, icons, sidebar indicators)
- **AND** the active schema for that item type defines a `color` field
- **THEN** the accent color SHALL be read from `schema.color`

#### Scenario: Item type without a schema color

- **WHEN** components render item-type UI
- **AND** the active schema does not define a `color` field (or no active schema exists for the type)
- **THEN** a default grey accent SHALL be used

### Requirement: Schema-driven icon rendering via curated MUI registry

The admin panel SHALL render schema-driven icons (stored as `schema.icon`) by resolving the stored name through a curated registry of MUI icons, rather than a namespace import of `@mui/icons-material`. This keeps the SPA bundle small (only the curated icons are bundled) while covering the consumables domain. The schema registry remains the source of truth for which icon a type uses; the curated registry only maps names to components.

#### Scenario: Item type with a registry icon

- **WHEN** a component renders a schema-driven icon (sidebar, dashboard cards, item table, item detail, schema list, schema editor)
- **AND** `schema.icon` matches an entry in the curated MUI icon registry
- **THEN** the corresponding MUI icon component SHALL be rendered

#### Scenario: Item type with an unregistered or absent icon

- **WHEN** a component renders a schema-driven icon
- **AND** `schema.icon` is absent or does not match any registry entry (e.g. a stale lucide name from before the migration)
- **THEN** a default fallback MUI icon SHALL be rendered

#### Scenario: Schema editor icon selection

- **WHEN** an admin edits a schema in the schema editor
- **THEN** the icon picker SHALL offer the curated registry's icon set (searchable by label)
- **AND** the selected icon name SHALL be persisted to `schema.icon`

#### Scenario: Existing item types after migration

- **WHEN** the migration ships
- **AND** existing item types still store pre-migration icon names (lucide component names) in `schema.icon`
- **THEN** those types SHALL render the fallback icon
- **AND** an admin SHALL be able to re-set each type's icon via the schema editor to restore a proper MUI icon (one-time manual pass, accepted breakage)

### Requirement: CSS variable export

The MUI theme SHALL expose its design tokens as CSS variables for use by any custom styling.

#### Scenario: CSS variables available

- **WHEN** the MUI theme is initialized with `cssVariables: true`
- **THEN** CSS custom properties SHALL be generated for all palette colors (e.g., `--mui-palette-primary-main`, `--mui-palette-surface-default`)
- **AND** CSS custom properties SHALL update when the theme toggles between light and dark

#### Scenario: Custom component using CSS variable

- **WHEN** a custom component needs to reference a theme color
- **THEN** the component MAY use `var(--mui-palette-primary-main)` in its styles
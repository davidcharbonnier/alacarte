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

### Requirement: Item-type accent colors

The admin panel SHALL use distinct accent colors for each item type, matching the Flutter client's item-type color mapping.

#### Scenario: Cheese item type

- **WHEN** components render cheese-related UI (badges, card accents, icons)
- **THEN** the accent color SHALL be `#673AB7` (deepPurple)

#### Scenario: Gin item type

- **WHEN** components render gin-related UI
- **THEN** the accent color SHALL be `#009688` (teal)

#### Scenario: Wine item type

- **WHEN** components render wine-related UI
- **THEN** the accent color SHALL be `#8E24AA` (purple)

#### Scenario: Coffee item type

- **WHEN** components render coffee-related UI
- **THEN** the accent color SHALL be `#795548` (brown)

#### Scenario: Chili sauce item type

- **WHEN** components render chili-sauce-related UI
- **THEN** the accent color SHALL be `#F44336` (red)

#### Scenario: Unknown item type

- **WHEN** components render UI for an item type not in the predefined mapping
- **THEN** the accent color SHALL be read from the schema's `color` field (server-driven)
- **AND** if no schema color exists, a default grey accent SHALL be used

### Requirement: CSS variable export

The MUI theme SHALL expose its design tokens as CSS variables for use by any custom styling.

#### Scenario: CSS variables available

- **WHEN** the MUI theme is initialized with `cssVariables: true`
- **THEN** CSS custom properties SHALL be generated for all palette colors (e.g., `--mui-palette-primary-main`, `--mui-palette-surface-default`)
- **AND** CSS custom properties SHALL update when the theme toggles between light and dark

#### Scenario: Custom component using CSS variable

- **WHEN** a custom component needs to reference a theme color
- **THEN** the component MAY use `var(--mui-palette-primary-main)` in its styles
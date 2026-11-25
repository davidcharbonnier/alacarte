# Admin Panel Design System

**Last Updated:** November 2026  
**Status:** Complete ✅

## Overview

The admin panel uses **MUI v6 with a Material Design 3 (M3) theme** as its design system. The single source of truth is `apps/admin/src/theme.ts`. There is no Tailwind, no `lib/config/design-system.ts`, and no custom component library — all UI is built from MUI components styled with theme tokens.

The M3 tonal palette is derived from a **deep purple seed** (`ColorScheme.fromSeed(Colors.deepPurple)`), matching the Flutter client's color scheme. Dark mode is first-class via MUI's `colorSchemes`.

**Related Documentation:**

- [Admin Authentication System](/docs/admin/authentication-system.md)
- [Admin Deployment](/docs/admin/deployment.md)
- [Backend Requirements](/docs/admin/backend-requirements.md)
- [Adding New Item Types](/docs/guides/adding-new-item-types.md)

---

## Theme Structure

`apps/admin/src/theme.ts` exports a `createTheme()` result with:

- **`colorSchemes`** — light and dark palettes (`cssVariables.colorSchemeSelector: 'class'`, toggled by a `dark`/`light` class on `<html>`)
- **`typography`** — M3 type scale on Roboto
- **`shape`** — base `borderRadius: 12`
- **`components`** — M3-flavored overrides for Button, Card, Paper, AppBar, Chip, TextField, Tab, Dialog, Fab, CssBaseline

Module augmentation extends MUI's `Palette` with M3 surface roles and `Typography` with the full M3 variant names (`headlineSmall`, `titleMedium`, `labelLarge`, …), so everything type-checks in `sx` and props.

## Provider Setup

`src/theme-context.tsx` wraps the app:

```tsx
<MuiThemeProvider theme={theme} defaultMode={initialMode}>
  <CssBaseline />
  <ThemeController>{children}</ThemeController>
</MuiThemeProvider>
```

`useThemeMode()` exposes `{ mode, toggle, setMode }`. Mode is persisted to `localStorage` under the key `theme` and applied as a class on `document.documentElement` (which drives the CSS-variable color scheme).

```tsx
const { mode, toggle } = useThemeMode();
```

## Color System

### Palette roles (light / dark)

| Role | Light | Dark | Use |
|------|-------|------|-----|
| `primary` | `#673AB7` | `#D0BCFF` | Brand actions |
| `secondary` | `#625B71` | `#CCC2DC` | Secondary accent |
| `tertiary` | `#7D5260` | `#EFB8C8` | Tertiary accent |
| `error` | `#B3261E` | `#F2B8B5` | Errors |
| `warning` | `#FF9800` | `#FFB74D` | Warnings |
| `success` | `#4CAF50` | `#81C784` | Success states |
| `background.default` | `#FEF7FF` | `#141218` | Page background |
| `surface` | `#FEF7FF` | `#141218` | Base surface |
| `surfaceVariant` | `#E7E0EC` | `#49454F` | Variant surface |
| `outline` / `outlineVariant` | `#79747E` / `#CAC4D0` | `#938F99` / `#49454F` | Borders, dividers |

### M3 surface containers

Five elevation-equivalent tiers, all first-class palette roles:

`surfaceContainerLowest` → `surfaceContainerLow` → `surfaceContainer` → `surfaceContainerHigh` → `surfaceContainerHighest`

(App shell: TopAppBar on `surfaceContainer`, NavigationDrawer on `surfaceContainerLow` — see `src/components/layout/app-shell.tsx`.)

**Rules:**

- Use surface roles for backgrounds, not hex values or alpha-tinted boxes (no `${hex}10` backgrounds — that pattern was removed with the old Tailwind stack).
- Item-type accent colors tint icons/indicators only; never use an accent as a page background.

## Typography

Roboto with the M3 type scale. Both default MUI variants and the extended M3 variants are available:

```tsx
<Typography variant="headlineSmall">Page title</Typography>
<Typography variant="titleMedium">Card title</Typography>
<Typography variant="labelLarge">Button-like label</Typography>
<Typography variant="body2" color="text.secondary">Secondary text</Typography>
```

Extended variants: `displayLarge/Medium/Small`, `headlineLarge/Medium/Small`, `titleLarge/Medium/Small`, `bodyLarge/Medium/Small`, `labelLarge/Medium/Small`. Buttons and tabs use `textTransform: 'none'` (no ALL CAPS).

## Shape & Component Overrides

Base radius `12`. Component defaults:

| Component | Override |
|-----------|----------|
| `MuiButton` | `disableElevation`, radius 20 (small 16, large 24), no text transform |
| `MuiIconButton` | radius 16 |
| `MuiCard` | `elevation: 0`, radius 16 |
| `MuiPaper` | `elevation: 0` |
| `MuiAppBar` | flat, `surfaceContainer` background, `outlineVariant` bottom border |
| `MuiChip` | radius 8, medium-weight label |
| `MuiOutlinedInput` | radius 12 |
| `MuiTab` | no text transform, medium weight |
| `MuiDialog` | paper radius 24 |
| `MuiFab` | medium, radius 16, no shadow |

## Item-Type Accents & Icons

Item types are **config-driven at runtime** — the backend schema registry supplies `schema.color` (hex) and `schema.icon` (name) per type. There is no hardcoded per-type color list in the frontend.

### Accent helpers (`src/theme.ts`)

```ts
import { getAccentColor, getAccentWithAlpha } from '../../theme';

const accent = getAccentColor(schema?.color);          // falls back to FALLBACK_ACCENT (#79747E)
const tint   = getAccentWithAlpha(accent, 0.12);       // alpha() blend for scrims/status only
```

- `getAccentColor(hex?)` — returns the schema color or a grey fallback
- `getAccentWithAlpha(hex, alpha)` — MUI `alpha()` blend
- Accent usage: small scrims, status indicators, icon tints — **never** page backgrounds or border-left stripes

### Icon registry (`src/lib/icons/icon-registry.ts`)

Curated registry — no namespace import of `@mui/icons-material`:

- `ICON_OPTIONS` — name/label list for schema editors
- `ICON_MAP` — name → component lookup
- `resolveIcon(name?)` — returns the component or `FALLBACK_ICON` (`HelpOutline`)

**Adding an icon:** extend `ICON_OPTIONS` and `ICON_MAP` together.

### Usage pattern (M3 tonal container)

```tsx
const accent = getAccentColor(schema?.color);
const Icon = resolveIcon(schema.icon);

<Box sx={{ bgcolor: 'surfaceContainerHighest', color: accent, borderRadius: '16px' }}>
  <Icon />
</Box>
```

Accent-on-surface-container tints adapt to light/dark automatically — that is why tinting beats solid hex backgrounds.

## Using the Theme in Components

### `sx` prop with theme tokens

Palette role names work directly as `sx` values — no raw hex:

```tsx
<Box sx={{ bgcolor: 'surfaceContainerLow', border: 1, borderColor: 'outlineVariant' }}>
  <Typography variant="titleMedium" sx={{ color: 'primary.main' }}>…</Typography>
</Box>
```

### Use MUI components, not custom ones

- Cards → `Card` (flat, radius 16), lists → `List`/`ListItemButton`, tables → `Table`/`DataGrid`
- Feedback → `Alert`, `Skeleton`, `Chip`
- Layout → `Box`, `Stack`, `Grid` with `sx` spacing tokens (`p: 3`, `gap: 2.5`)
- Only fall back to `style={{}}` for runtime accent colors (schema-driven values the theme can't know)

### Dark mode

Never hardcode light-only colors. Use palette roles, surface containers, and accent tints — they resolve per mode via CSS variables.

## Conventions (from `apps/admin/AGENTS.md`)

- Theme tokens live only in `src/theme.ts`; no `lib/config/design-system.ts`, no Tailwind utilities, no hex-opacity tinted boxes
- M3 surface containers are first-class palette roles — prefer them over `elevation` shadows
- Icons via the curated registry in `src/lib/icons/icon-registry.ts` (no namespace import)
- Item types have no frontend color list: read `schema.color` / `schema.icon` at render with `getAccentColor` / `resolveIcon`
- Verify with `npm run build` (Vite production build only; it does not type-check) and `npm run typecheck`

## Related Documentation

- [Adding New Item Types](/docs/guides/adding-new-item-types.md)
- [Backend Requirements](/docs/admin/backend-requirements.md)

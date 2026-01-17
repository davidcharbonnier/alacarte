# Admin Panel Design System

**Last Updated:** January 2025  
**Status:** Complete ✅

## Overview

The admin panel has a comprehensive design system that matches the Flutter client app for visual consistency. This document covers the complete design system implementation including colors, components, and enhancements.

---

## Table of Contents

1. [Design Tokens](/docs/admin/design-system.md#design-tokens)
2. [Color System](/docs/admin/design-system.md#color-system)
3. [Component Enhancements](/docs/admin/design-system.md#component-enhancements)
4. [Dark Mode Support](/docs/admin/design-system.md#dark-mode-support)
5. [Usage Guidelines](/docs/admin/design-system.md#usage-guidelines)

---

## Design Tokens

### Location
`apps/admin/lib/config/design-system.ts`

### What's Included

**Item Type Colors:**
- Cheese: Deep purple (#673AB7)
- Gin: Teal (#009688)
- Wine: Deep purple variant (#8E24AA)

**Brand Colors:**
- Primary, secondary, error, success, warning

**Rating Colors:**
- Personal, recommendation, community

**Spacing Scale:**
- xs(4px), s(8px), m(16px), l(24px), xl(32px), xxl(48px)

**Border Radius:**
- xs(2px), s(4px), m(8px), l(12px), xl(16px)

**Icon Sizes:**
- xs(12px), s(16px), m(24px), l(32px), xl(48px)

**Font Sizes:**
- xs(10px), s(12px), m(14px), l(16px), xl(20px), xxl(24px)

**Layout Constants:**
- Max content width: 600px
- Sidebar width: 256px

**Animation Durations:**
- Fast: 200ms, Normal: 300ms, Slow: 500ms

### Helper Functions

```typescript
getItemTypeColor(itemType: string)  // Get color config
getItemTypeClasses(itemType: string)  // Get Tailwind classes
```

---

## Color System

### Item Type Colors

| Type   | Hex       | Icon | Usage                  |
|--------|-----------|------|------------------------|
| Cheese | #673AB7   | 🍕   | Deep purple (primary)  |
| Gin    | #009688   | 🍸   | Teal                   |
| Wine   | #8E24AA   | 🍷   | Deep purple variant    |

### Brand Colors

| Name      | Hex     | Purpose                    |
|-----------|---------|----------------------------|
| Primary   | #673AB7 | Main brand color           |
| Secondary | #9C27B0 | Secondary accent           |
| Error     | #F44336 | Error states               |
| Success   | #4CAF50 | Success states             |
| Warning   | #FF9800 | Warning states             |

### Global CSS Variables

**Location:** `apps/admin/app/globals.css`

```css
--color-cheese: #673AB7;
--color-gin: #009688;
--color-wine: #8E24AA;
```

Now available as Tailwind utilities: `text-cheese`, `bg-gin`, etc.

---

## Component Enhancements

### 1. Dashboard

**Status:** Complete ✅  
**File:** `components/dashboard/dashboard-stats.tsx`

**Features:**
- Flutter-style item type cards
- Colored icons with background
- Hover effects
- Click-through links
- Dynamic item counts

**Visual:**
```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ 🍕 Cheeses  │  │ 🍸 Gins     │  │ 🍷 Wines    │
│ 42 items    │  │ 15 items    │  │ 28 items    │
└─────────────┘  └─────────────┘  └─────────────┘
```

### 2. Sidebar

**Status:** Complete ✅  
**File:** `components/layout/sidebar.tsx`

**Features:**
- Dynamic item type loading from config
- Colored icon backgrounds
- Active state indicators (colored left border)
- Section organization (Dashboard | Item Types | Users)
- Hover animations

**Visual:**
```
Dashboard
─────────────
ITEM TYPES
🍕 Cheeses    [purple]
🍸 Gins       [teal]
🍷 Wines      [purple]
─────────────
👥 Users
```

### 3. List Pages

**Status:** Complete ✅  
**Files:** 
- `app/(dashboard)/[itemType]/page.tsx`
- `components/shared/generic-item-table.tsx`

**Features:**
- Colored header with icon
- Colored table headers
- Colored "Seed Data" button
- Colored "View" buttons
- Alternating row colors (3% item type color)
- Dynamic hover (8% item type color)
- Enhanced empty states

**Visual:**
```
🍕 Cheeses                [Seed Data]
                          ↑ purple

Name    Type    Origin    Actions
────────────────────────────────
Oka     Soft    Quebec    [View]  ← transparent
Brie    Soft    France    [View]  ← 3% purple
Ched... Hard    UK        [View]  ← transparent
                                  ↑ hover: 8%
```

### 4. Detail Pages

**Status:** Complete ✅  
**File:** `components/shared/generic-item-detail.tsx`

**Features:**
- Colored header icon
- Colored "Back" button
- Colored left border on cards (4px)
- Colored card titles
- Better spacing and layout

**Visual:**
```
[Back to Cheeses] ← purple

🍕 Oka Cheese

┃ Basic Information    ┃ Description
┃ [purple border]      ┃ [purple border]
```

### 5. Forms

**Status:** Complete ✅  
**File:** `components/shared/generic-seed-form.tsx`

**Features:**
- Colored "Back" button
- Colored card border
- Colored "Validate" button (outline)
- Colored "Import" button (solid)
- Colored "View" button (outline)

**Visual:**
```
[Back to Cheeses] ← purple

┃ Bulk Import          ← purple title
┃ [purple border]
┃
┃ [Validate Data]      ← purple outline
┃ [Import Data]        ← purple solid
```

### 6. Tables

**Status:** Complete ✅  
**File:** `components/shared/generic-item-table.tsx`

**Features:**
- Colored table border (20% opacity)
- Alternating row backgrounds
- Dynamic hover effects
- Enhanced empty states with colored icons
- Colored result counter

**Empty State:**
```
      ⊙ ∅         ← purple circle
  No cheeses found
Try adjusting search
```

---

## Dark Mode Support

### Status: Complete ✅

**Files:**
- `components/theme-provider.tsx`
- `components/theme-toggle.tsx`
- `components/providers.tsx`

### Features

- **Theme Toggle:** Moon/Sun icon in header
- **Persistence:** Saves preference to localStorage
- **System Detection:** Auto-detects system preference
- **No Flash:** Prevents flash of wrong theme
- **All Components:** Work perfectly in both modes

### Usage

**For Users:**
```
Light Mode: 🌙 (click to go dark)
Dark Mode:  ☀️  (click to go light)
```

**For Developers:**
```typescript
import { useTheme } from '@/components/theme-provider';

const { theme, toggleTheme, setTheme } = useTheme();
```

### Color Behavior

Item type colors automatically adjust brightness in dark mode:
- Light mode: Full saturation
- Dark mode: Lighter variants
- Opacity levels work in both modes

---

## Usage Guidelines

### Using Colors in Components

```typescript
import { getItemTypeColor } from '@/lib/config/design-system';

const colors = getItemTypeColor(itemType);

// Solid background
style={{ backgroundColor: colors.hex, color: 'white' }}

// Outline
style={{ borderColor: colors.hex, color: colors.hex }}

// Ghost/Text
style={{ color: colors.hex }}

// Backgrounds with opacity
style={{ backgroundColor: `${colors.hex}10` }} // 10%
```

### Opacity Levels

- **03%** - Very subtle (alternating rows)
- **08%** - Light (hover states)
- **10%** - Subtle (icon backgrounds, empty states)
- **20%** - Moderate (borders, table outline)
- **25%** - Medium (active sidebar icons)
- **100%** - Full color (text, solid elements)

### Theme-Aware Styling

Always use CSS variables for backgrounds, text, and borders:

```tsx
// Background
<div className="bg-background">

// Text
<h1 className="text-foreground">
<p className="text-muted-foreground">

// Borders
<div className="border-border">

// Cards (already theme-aware)
<Card>
```

### Component Pattern

```tsx
// Get colors
const colors = getItemTypeColor(itemType);
const IconComponent = (Icons as any)[config.icon];

// Header with colored icon
<div className="flex items-center gap-3">
  <div 
    className="w-12 h-12 rounded-xl flex items-center justify-center"
    style={{ backgroundColor: `${colors.hex}20` }}
  >
    <IconComponent className="w-6 h-6" style={{ color: colors.hex }} />
  </div>
  <h1>{title}</h1>
</div>

// Colored button (primary)
<Button
  style={{ backgroundColor: colors.hex, color: 'white' }}
  className="hover:opacity-90"
>

// Colored button (outline)
<Button
  variant="outline"
  style={{ borderColor: colors.hex, color: colors.hex }}
>

// Card with colored border
<Card 
  className="border-l-4"
  style={{ borderLeftColor: colors.hex }}
>
```

---

## Adding New Item Types

When adding a new item type:

1. **Add config** to `lib/config/item-types.ts`
2. **Add color** to `lib/config/design-system.ts`
3. **Done!** All components automatically get the color

The sidebar will automatically include the new item type with its color.

**Example:**
```typescript
// design-system.ts
export const itemTypeColors = {
  // ... existing
  beer: {
    hex: '#FFA726',  // Orange
    rgb: 'rgb(255, 167, 38)',
    hsl: 'hsl(36, 100%, 57%)',
    className: 'text-[#FFA726] bg-[#FFA726]/10',
  },
} as const;

// item-types.ts
beer: {
  name: 'beer',
  labels: { singular: 'Beer', plural: 'Beers' },
  icon: 'Beer',
  color: itemTypeColors.beer.hex,
  // ... rest of config
}
```

---

## Testing

### Visual Checks

**Light Mode:**
- [ ] All item type colors visible
- [ ] Good contrast on white background
- [ ] No "washed out" colors

**Dark Mode:**
- [ ] All item type colors visible
- [ ] Good contrast on dark background
- [ ] No "blinding" bright colors
- [ ] Opacity levels still work

### Components

- [ ] Dashboard cards
- [ ] Sidebar navigation
- [ ] List page headers
- [ ] Tables (headers, rows, empty states)
- [ ] Detail pages
- [ ] Forms (all buttons)
- [ ] Theme toggle works

---

## Related Documentation

- [Adding New Item Types](/docs/guides/adding-new-item-types.md)
- [Admin Checklist](/docs/guides/admin-checklist.md)
- [Backend Requirements](/docs/admin/backend-requirements.md)

---

## Benefits

1. **Visual Consistency** - Matches Flutter client
2. **Automatic Scaling** - New item types get colors automatically
3. **Professional Polish** - Modern, branded appearance
4. **Maintainability** - Single source of truth
5. **Dark Mode** - Full support
6. **Accessibility** - Good contrast in both themes
7. **Developer Experience** - Easy to use, well-documented

---

**The admin panel now has a complete, professional design system that matches your Flutter app!** 🎨

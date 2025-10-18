# Admin Panel Checklist - Adding New Item Types

**Last Updated:** January 2025  
**Estimated Time:** ~5 minutes per item type (was 7, now even faster!)

This checklist covers the exact steps to add a new item type to the Next.js admin panel. Thanks to the config-driven architecture and dynamic sidebar, everything works automatically after these two simple steps.

---

## 📋 Implementation Checklist

### ✅ Step 1: Add Item Type Configuration (~3 min)

**File:** `apps/admin/lib/config/item-types.ts`

Add your item type configuration to the `itemTypesConfig` object:

```typescript
wine: {
  name: 'wine',
  labels: {
    singular: 'Wine',
    plural: 'Wines',
  },
  icon: 'Wine',  // Lucide icon name
  color: itemTypeColors.wine.hex,  // ← ADD THIS (from design-system.ts)
  
  fields: [
    {
      key: 'name',              // Must match API model field
      label: 'Name',            // Display label in forms
      type: 'text',             // Field type: 'text', 'textarea', 'number', 'checkbox'
      required: true,           // Match API validation
      maxLength: 200,           // Optional: character limit
      placeholder: 'e.g., ...',  // Optional: placeholder text
      helperText: '...',        // Optional: helper text below field
    },
    // ... add all other fields
  ],
  
  table: {
    columns: ['name', 'color', 'country'],           // Columns to show in list view
    searchableFields: ['name', 'color', 'country'],  // Fields to search through
    defaultSort: 'name',                             // Default sort column
    sortOrder: 'asc',                                // 'asc' or 'desc'
  },
  
  apiEndpoints: {
    list: '/api/wine/all',
    detail: (id: number) => `/api/wine/${id}`,
    deleteImpact: (id: number) => `/admin/wine/${id}/delete-impact`,
    delete: (id: number) => `/admin/wine/${id}`,
    seed: '/admin/wine/seed',
    validate: '/admin/wine/validate',
  },
},
```

**Field Types Available:**
- `'text'` - Single-line text input
- `'textarea'` - Multi-line text input
- `'number'` - Numeric input (for int/float fields)
- `'checkbox'` - Boolean checkbox (for bool fields) - **displays with icons** ✓/✗

**Display Features:**
- **Boolean fields:** Show green checkmark (✓) for true, gray X (✗) for false
- **Empty text/number:** Show "Not specified" (italic, gray) in detail view, "—" in table
- **Empty boolean:** Treated as false, shows gray X (✗)

**Field Properties:**
- `key` (required) - Must match API model JSON field name exactly
- `label` (required) - Display label for the field
- `type` (required) - Field input type
- `required` (required) - Whether field is required (match API validation)
- `maxLength` (optional) - Character limit for text fields
- `placeholder` (optional) - Placeholder text
- `helperText` (optional) - Helper text shown below field

**Icon Options:**
Use any [Lucide React](https://lucide.dev/) icon name:
- `'Wine'`, `'ChefHat'`, `'Coffee'`, `'Beer'`, `'Cookie'`, etc.

---

### ✅ Step 2: Add Color to Design System (~2 min)

**File:** `apps/admin/lib/config/design-system.ts`

Add the new color to the `itemTypeColors` object:

```typescript
export const itemTypeColors = {
  cheese: {
    hex: '#673AB7',
    rgb: 'rgb(103, 58, 183)',
    hsl: 'hsl(262, 52%, 47%)',
    className: 'text-[#673AB7] bg-[#673AB7]/10',
  },
  gin: {
    hex: '#009688',
    rgb: 'rgb(0, 150, 136)',
    hsl: 'hsl(174, 100%, 29%)',
    className: 'text-[#009688] bg-[#009688]/10',
  },
  wine: {
    hex: '#8E24AA',
    rgb: 'rgb(142, 36, 170)',
    hsl: 'hsl(288, 65%, 40%)',
    className: 'text-[#8E24AA] bg-[#8E24AA]/10',
  },
  beer: {  // ← ADD YOUR NEW ITEM TYPE
    hex: '#FFA726',        // Choose a distinctive color
    rgb: 'rgb(255, 167, 38)',
    hsl: 'hsl(36, 100%, 57%)',
    className: 'text-[#FFA726] bg-[#FFA726]/10',
  },
} as const;
```

**Color Selection Tips:**
- Choose colors that stand out from existing ones
- Ensure good contrast for accessibility
- Test in both light and dark modes
- Common choices: Orange (#FFA726), Blue (#2196F3), Red (#F44336), Amber (#FFC107)
- You can also use the RGB/HSL values if you prefer those formats

**Properties:**
- `hex` - Hex color code (e.g., `#FFA726`)
- `rgb` - RGB color string (e.g., `rgb(255, 167, 38)`)
- `hsl` - HSL color string (e.g., `hsl(36, 100%, 57%)`)
- `className` - Tailwind utility classes for the color

---

### ✅ Step 3: ~~Update Navigation~~ **No Longer Needed!** 🎉

**The sidebar is now dynamic!** It automatically loads item types from your config.

When you add a new item type, it will automatically appear in the sidebar with its color - no manual updates required!

**What happens automatically:**
- Item type appears in "Item Types" section
- Icon displays with correct color
- Link routes to `/{itemType}` page
- Active states work correctly
- Hover effects included

---

## ✅ That's It!

After these **two** steps, the following features work automatically:

### 🎯 Automatic Features

**List View (`/wine`):**
- ✅ Table with configured columns
- ✅ Search across searchable fields
- ✅ Sorting by columns
- ✅ Pagination
- ✅ Item count display
- ✅ "Seed Items" button
- ✅ Loading states
- ✅ Error handling

**Detail View (`/wine/[id]`):**
- ✅ Display all fields
- ✅ Formatted field values
- ✅ Delete button
- ✅ Back navigation
- ✅ Loading states
- ✅ Error handling

**Delete Impact Assessment:**
- ✅ Shows affected ratings count
- ✅ Shows affected users count
- ✅ Shows sharing count
- ✅ Lists affected users with details
- ✅ Confirmation dialog
- ✅ Cascade deletion with transaction

**Bulk Seed Import:**
- ✅ **File upload** (.json from computer) - **NEW!**
- ✅ **URL input** (remote JSON file)
- ✅ JSON validation before import
- ✅ Natural key duplicate detection
- ✅ Progress feedback
- ✅ Success/error summary
- ✅ Detailed error messages

**Dashboard Card:**
- ✅ "Total Wines" stat card
- ✅ Real-time count
- ✅ Auto-updates on changes

---

## 📝 Field Mapping Guide

### API Model → Admin Config Mapping

| API Type | Admin Type | Example |
|----------|------------|---------|
| `string` | `'text'` | Name, Producer, Region |
| `string` (long) | `'textarea'` | Description |
| `int` | `'number'` | Vintage, ABV |
| `float64` | `'number'` | Alcohol %, Sugar |
| `bool` | `'checkbox'` | Organic, Featured |

### Required vs Optional

**Match your API validation:**
```go
// API Model
type Wine struct {
    Name    string  `gorm:"not null"`  // ← Required in API
    Region  string                      // ← Optional in API
}
```

```typescript
// Admin Config
fields: [
  { key: 'name', required: true },    // ← Required: true
  { key: 'region', required: false }, // ← Required: false
]
```

---

## 🔍 Verification Steps

### Test List View
1. Navigate to `/{itemType}` (e.g., `/wine`)
2. ✅ Table displays with configured columns
3. ✅ Search works across searchable fields
4. ✅ Sorting works on columns
5. ✅ "Seed Items" button appears

### Test Seed Function
1. Click "Seed Items" button
2. Enter valid JSON URL
3. ✅ Validation runs before import
4. ✅ Duplicate detection works (natural key)
5. ✅ Success/error summary displays
6. ✅ Items appear in table

### Test Detail View
1. Click on any item in table
2. ✅ All fields display correctly
3. ✅ Number fields show numeric values
4. ✅ Checkbox fields show ✓ Yes (green) or ✗ No (gray)
5. ✅ Empty fields show "Not specified" (italic, gray)
6. ✅ Description in textarea format

### Test Delete Impact
1. Click "Delete" on item detail page
2. ✅ Impact assessment modal shows
3. ✅ Ratings count displays
4. ✅ Users affected list displays
5. ✅ Confirmation required
6. ✅ Cascade deletion works

### Test Dashboard
1. Navigate to `/` (Dashboard)
2. ✅ "Total {Items}" card appears
3. ✅ Count is accurate
4. ✅ Updates after seed/delete

---

## 🐛 Common Issues

### Issue: Config not loading
**Solution:** Check TypeScript syntax in `item-types.ts`
- Missing comma after config block
- Incorrect property names
- Mismatched quotes

### Issue: Routes 404
**Solution:** Backend endpoints must exist first
- Verify API endpoints are implemented
- Check API is running
- Verify endpoint paths match config

### Issue: Fields not displaying
**Solution:** Check field key matches API
```typescript
// Admin config
{ key: 'grape' }

// Must match API JSON tag
Grape string `json:"grape"`
```

### Issue: Icon not showing
**Solution:** Use valid Lucide icon name
- Check [Lucide Icons](https://lucide.dev/)
- Icon name is case-sensitive
- Common icons: Wine, ChefHat, Coffee, Beer

### Issue: Validation not working
**Solution:** Check required flags match API
- API `gorm:"not null"` → Admin `required: true`
- API optional → Admin `required: false`

---

## 📚 Related Documentation

- [Adding New Item Types Guide](adding-new-item-types.md) - Complete platform guide
- [Backend Checklist](backend-checklist.md) - API implementation steps
- [Client Checklist](client-checklist.md) - Flutter implementation steps

---

## 💡 Pro Tips

1. **Copy existing config** - Use gin or wine as template
2. **Match field order** - Keep same order as API model for clarity
3. **Use helper text** - Clarify ambiguous fields with helperText
4. **Test incrementally** - Test after each step (config → navigation)
5. **Searchable fields** - Include all fields users might search by
6. **Table columns** - Show 3-5 most important fields (keeps table readable)
7. **Boolean fields** - Always use `'checkbox'` type - displays with icons automatically
8. **Nullable fields** - Empty values display elegantly without special handling

---

## ✅ Completion Checklist

- [ ] Config added to `item-types.ts`
- [ ] Color added to `design-system.ts`
- [ ] ~~Navigation updated in sidebar~~ (automatic now!)
- [ ] All API fields included
- [ ] Required flags match API validation
- [ ] Field types match API types
- [ ] Table columns configured (3-5 fields)
- [ ] Searchable fields configured
- [ ] API endpoints configured
- [ ] Navigation updated in `sidebar.tsx`
- [ ] List view tested (`/{itemType}`)
- [ ] Detail view tested (`/{itemType}/[id]`)
- [ ] Seed function tested
- [ ] Delete impact tested
- [ ] Dashboard card appears

---

**Total Time:** ~5 minutes  
**Result:** Fully functional admin panel with branded colors and automatic navigation for new item type 🚀

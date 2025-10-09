# Adding New Item Types - Admin Panel

**Last Updated:** January 2025  
**Status:** ✅ Generic Config System Complete  
**Current Item Types:** Cheese, Gin  
**Time Estimate:** ~5 minutes per item type

---

## 🎉 Config-Based Generic Architecture

The admin panel uses a **configuration-driven approach** where all item types are defined in `lib/config/item-types.ts`, and generic components handle all rendering and operations automatically.

### **What Works Automatically**

When you add a new item type to the config:

✅ **List View** - Generic table renders with configured columns  
✅ **Detail View** - Generic detail display with all fields  
✅ **Delete Impact** - Generic impact assessment page  
✅ **Seed Form** - Generic bulk import interface  
✅ **Search/Filter** - Based on configured searchable fields  
✅ **Navigation** - Dynamic routes work automatically  
✅ **Data Transformation** - GORM format handling  
✅ **Loading States** - Consistent across all types  
✅ **Error Handling** - Unified error messages  
✅ **Dashboard Stats** - Auto-generates stat cards  

**You only configure:** Field definitions, table columns, labels, icons (single config entry)

**Time savings:** 20 minutes → **5 minutes** (75% faster!)

---

## 📋 Adding a New Item Type

### **Complete Example: Adding Wine**

#### **Step 1: Add to Config** (~3 min)

**File:** `lib/config/item-types.ts`

```typescript
// Add to itemTypesConfig object:
wine: {
  name: 'wine',
  labels: {
    singular: 'Wine',
    plural: 'Wines',
  },
  icon: 'Wine', // Any lucide-react icon name
  
  fields: [
    {
      key: 'name',
      label: 'Name',
      type: 'text',
      required: true,
      maxLength: 100,
      placeholder: 'e.g., Château Margaux',
    },
    {
      key: 'varietal',
      label: 'Varietal',
      type: 'text',
      required: true,
      maxLength: 100,
      placeholder: 'e.g., Cabernet Sauvignon',
      helperText: 'Grape variety',
    },
    {
      key: 'producer',
      label: 'Producer',
      type: 'text',
      required: true,
      maxLength: 100,
      placeholder: 'e.g., Château Margaux',
    },
    {
      key: 'origin',
      label: 'Origin',
      type: 'text',
      required: true,
      maxLength: 100,
      placeholder: 'e.g., Bordeaux, France',
    },
    {
      key: 'vintage',
      label: 'Vintage',
      type: 'number',
      required: false,
      min: 1900,
      max: new Date().getFullYear(),
      placeholder: 'e.g., 2015',
    },
    {
      key: 'description',
      label: 'Description',
      type: 'textarea',
      required: false,
      maxLength: 500,
      placeholder: 'Optional description...',
    },
  ],
  
  table: {
    columns: ['name', 'varietal', 'producer', 'origin', 'vintage'],
    searchableFields: ['name', 'varietal', 'origin', 'producer'],
    defaultSort: 'name',
    sortOrder: 'asc',
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

#### **Step 2: Update Navigation** (~2 min)

**File:** `components/layout/sidebar.tsx`

```typescript
import { Wine } from 'lucide-react'; // Add import if not already there

const navigationItems = [
  { name: 'Dashboard', href: '/', iconName: 'Home' },
  { name: 'Cheese', href: '/cheese', iconName: 'ChefHat' },
  { name: 'Gin', href: '/gin', iconName: 'Wine' },
  { name: 'Wine', href: '/wine', iconName: 'Wine' }, // ADD THIS LINE
  { name: 'Users', href: '/users', iconName: 'Users' },
];
```

#### **Done! ✅**

That's it. Now you can:
- Navigate to `/wine` - List view works
- Click any wine - Detail view works
- Click delete - Impact assessment works
- Click seed - Bulk import works
- Dashboard shows "Total Wines" card automatically

**Total time: ~5 minutes**

---

## 🏗️ Generic Architecture Details

### **How It Works**

```
User navigates to /wine
    ↓
Dynamic route: app/(dashboard)/[itemType]/page.tsx
    ↓
Validates: isValidItemType('wine') ✅
    ↓
Loads config: getItemTypeConfig('wine')
    ↓
Creates API: getItemApi<Wine>('wine')
    ↓
Renders: <GenericItemTable itemType="wine" items={wines} />
    ↓
Table reads columns: ['name', 'varietal', 'producer', 'origin', 'vintage']
    ↓
Displays: Wine table with correct columns ✅
```

### **File Structure**

**Config Layer:**
```
lib/config/item-types.ts          # Single source of truth
lib/types/item-config.ts           # TypeScript types for config
```

**Generic Layer:**
```
lib/api/generic-item-api.ts       # API factory for all types
components/shared/
  ├── generic-item-table.tsx       # List view
  ├── generic-item-detail.tsx      # Detail view
  ├── generic-delete-impact.tsx    # Delete impact
  └── generic-seed-form.tsx        # Bulk import
```

**Route Layer:**
```
app/(dashboard)/[itemType]/
  ├── page.tsx                     # List
  ├── [id]/page.tsx                # Detail
  ├── [id]/delete/page.tsx         # Delete impact
  └── seed/page.tsx                # Seed
```

**No item-specific files needed!**

---

## 🔧 Field Configuration Options

### **Text Field**
```typescript
{
  key: 'name',
  label: 'Name',
  type: 'text',
  required: true,
  maxLength: 100,
  minLength: 2,
  placeholder: 'Enter name...',
  helperText: 'Optional help text',
}
```

### **Textarea Field**
```typescript
{
  key: 'description',
  label: 'Description',
  type: 'textarea',
  required: false,
  maxLength: 500,
  placeholder: 'Optional description...',
}
```

### **Number Field**
```typescript
{
  key: 'vintage',
  label: 'Vintage',
  type: 'number',
  required: false,
  min: 1900,
  max: 2025,
  placeholder: '2015',
}
```

### **Select Field (Future)**
```typescript
{
  key: 'type',
  label: 'Type',
  type: 'select',
  required: true,
  options: [
    { value: 'red', label: 'Red Wine' },
    { value: 'white', label: 'White Wine' },
    { value: 'rosé', label: 'Rosé' },
  ],
}
```

---

## 🎯 What's Reused (Everything!)

**Generic Components:**
- GenericItemTable - Works for any data with any columns
- GenericItemDetail - Displays any fields automatically
- GenericDeleteImpact - Same UI for all types
- GenericSeedForm - Same import flow for all types

**Generic Infrastructure:**
- API client factory - Creates type-safe clients
- Data transformation - Handles GORM automatically
- TanStack Query - Same caching for all types
- Error handling - Same utilities
- Loading states - Same spinners

**No Duplication:**
- Zero code duplication between item types
- One fix benefits all types
- New features added once, all types get them
- Consistency enforced by architecture

---

## 🔄 Backend Requirements

Before adding a new item type, backend must have:

```go
// Public endpoints (reused by admin)
GET  /api/wine/all          // List all wines
GET  /api/wine/:id          // Get wine details

// Admin-only endpoints (to implement)
GET    /admin/wine/:id/delete-impact  // Impact assessment
DELETE /admin/wine/:id                // Delete with cascading
POST   /admin/wine/seed               // Bulk import
POST   /admin/wine/validate           // Validate JSON (optional)
```

Admin panel works with mocks until backend endpoints are ready. Set `USE_MOCKS = false` in `lib/api/generic-item-api.ts` when ready.

---

## 💡 Pro Tips

1. **Copy existing config** - Use cheese or gin as template
2. **Test incrementally** - Add config, check /wine works
3. **Consistent naming** - Use lowercase for itemType ('wine' not 'Wine')
4. **Icon names** - Must match lucide-react exports exactly
5. **Field keys** - Must match backend JSON field names
6. **Searchable fields** - Choose fields users will search by

---

## 🎯 Customization (Future)

If you need type-specific behavior:

```typescript
wine: {
  // ... standard config
  
  customization: {
    // Custom detail renderer (if needed)
    detailComponent: WineDetailCustom,
    
    // Additional validation (if needed)
    customValidation: (wine) => {
      if (wine.vintage > new Date().getFullYear()) {
        return ['Vintage cannot be in the future'];
      }
      return [];
    },
  },
}
```

Generic components check for customizations and use them when present.

---

## 📚 Related Documentation

- [Backend Requirements](backend-requirements.md) - API specifications
- [Phased Implementation](phased-implementation.md) - Development progress
- [Authentication System](authentication-system.md) - NextAuth.js setup

---

**Built with Config-Driven Generic Architecture - Add item types in minutes, maintain consistency forever.**

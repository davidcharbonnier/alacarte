import { ItemTypeRegistry, ItemTypeConfig } from '../types/item-config';
import { itemTypeColors, getItemTypeColor } from './design-system';

// Re-export types for convenience
export type { ItemTypeConfig } from '../types/item-config';

/**
 * Central configuration for all item types
 * 
 * To add a new item type:
 * 1. Add configuration here
 * 2. Update navigation in components/layout/sidebar.tsx
 * 3. Done! All pages and components work automatically
 */
export const itemTypesConfig: ItemTypeRegistry = {
  cheese: {
    name: 'cheese',
    labels: {
      singular: 'Cheese',
      plural: 'Cheeses',
    },
    icon: 'Pizza',
    color: itemTypeColors.cheese.hex,
    
    fields: [
      {
        key: 'name',
        label: 'Name',
        type: 'text',
        required: true,
        maxLength: 100,
        placeholder: 'e.g., Oka, Cheddar',
      },
      {
        key: 'type',
        label: 'Type',
        type: 'text',
        required: true,
        maxLength: 100,
        placeholder: 'e.g., Pâte pressée, Pâte molle',
        helperText: 'Cheese texture/aging type',
      },
      {
        key: 'origin',
        label: 'Origin',
        type: 'text',
        required: true,
        maxLength: 100,
        placeholder: 'e.g., Quebec, France',
      },
      {
        key: 'producer',
        label: 'Producer',
        type: 'text',
        required: true,
        maxLength: 100,
        placeholder: 'e.g., Fromagerie d\'Oka',
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
      columns: ['name', 'type', 'origin', 'producer'],
      searchableFields: ['name', 'type', 'origin', 'producer'],
      defaultSort: 'name',
      sortOrder: 'asc',
    },
    
    apiEndpoints: {
      list: '/api/cheese/all',
      detail: (id: number) => `/api/cheese/${id}`,
      deleteImpact: (id: number) => `/admin/cheese/${id}/delete-impact`,
      delete: (id: number) => `/admin/cheese/${id}`,
      seed: '/admin/cheese/seed',
      validate: '/admin/cheese/validate',
    },
  },
  
  gin: {
    name: 'gin',
    labels: {
      singular: 'Gin',
      plural: 'Gins',
    },
    icon: 'Wine',
    color: itemTypeColors.gin.hex,
    
    fields: [
      {
        key: 'name',
        label: 'Name',
        type: 'text',
        required: true,
        maxLength: 100,
        placeholder: 'e.g., Ungava, Hendrick\'s',
      },
      {
        key: 'producer',
        label: 'Producer',
        type: 'text',
        required: true,
        maxLength: 100,
        placeholder: 'e.g., Les Spiritueux Ungava',
      },
      {
        key: 'origin',
        label: 'Origin',
        type: 'text',
        required: false,
        maxLength: 100,
        placeholder: 'e.g., Quebec, Scotland',
      },
      {
        key: 'profile',
        label: 'Profile',
        type: 'text',
        required: true,
        maxLength: 100,
        placeholder: 'e.g., Forestier, Floral',
        helperText: 'Flavor profile or style',
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
      columns: ['name', 'producer', 'origin', 'profile'],
      searchableFields: ['name', 'producer', 'origin', 'profile'],
      defaultSort: 'name',
      sortOrder: 'asc',
    },
    
    apiEndpoints: {
      list: '/api/gin/all',
      detail: (id: number) => `/api/gin/${id}`,
      deleteImpact: (id: number) => `/admin/gin/${id}/delete-impact`,
      delete: (id: number) => `/admin/gin/${id}`,
      seed: '/admin/gin/seed',
      validate: '/admin/gin/validate',
    },
  },
  
  wine: {
    name: 'wine',
    labels: {
      singular: 'Wine',
      plural: 'Wines',
    },
    icon: 'Wine',
    color: itemTypeColors.wine.hex,
    
    fields: [
      {
        key: 'name',
        label: 'Name',
        type: 'text',
        required: true,
        maxLength: 200,
        placeholder: 'e.g., Mas Bruguière L\'Arbouse',
      },
      {
        key: 'color',
        label: 'Color',
        type: 'select',
        required: true,
        options: [
          { value: 'Rouge', label: 'Rouge' },
          { value: 'Blanc', label: 'Blanc' },
          { value: 'Rosé', label: 'Rosé' },
          { value: 'Mousseux', label: 'Mousseux' },
          { value: 'Orange', label: 'Orange' },
        ],
        helperText: 'Wine color/type',
      },
      {
        key: 'country',
        label: 'Country',
        type: 'text',
        required: true,
        maxLength: 100,
        placeholder: 'e.g., France, Spain, Italy',
      },
      {
        key: 'producer',
        label: 'Producer',
        type: 'text',
        required: false,
        maxLength: 200,
        placeholder: 'e.g., Mas Bruguière',
      },
      {
        key: 'region',
        label: 'Region',
        type: 'text',
        required: false,
        maxLength: 100,
        placeholder: 'e.g., Languedoc-Roussillon, Rioja',
      },
      {
        key: 'grape',
        label: 'Grape Varieties',
        type: 'text',
        required: false,
        maxLength: 200,
        placeholder: 'e.g., Syrah 50%, Grenache 25%',
      },
      {
        key: 'designation',
        label: 'Designation',
        type: 'text',
        required: false,
        maxLength: 100,
        placeholder: 'e.g., Pic Saint-Loup, AOC',
      },
      {
        key: 'alcohol',
        label: 'Alcohol %',
        type: 'number',
        required: false,
        placeholder: 'e.g., 13.5',
      },
      {
        key: 'sugar',
        label: 'Sugar (g/L)',
        type: 'number',
        required: false,
        placeholder: 'e.g., 2.0',
      },
      {
        key: 'organic',
        label: 'Organic',
        type: 'checkbox',
        required: false,
      },
      {
        key: 'description',
        label: 'Description',
        type: 'textarea',
        required: false,
        maxLength: 1000,
        placeholder: 'Optional description...',
      },
    ],
    
    table: {
      columns: ['name', 'color', 'country', 'producer', 'region'],
      searchableFields: ['name', 'color', 'country', 'producer', 'region', 'grape', 'designation'],
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
  
  coffee: {
    name: 'coffee',
    labels: {
      singular: 'Coffee',
      plural: 'Coffees',
    },
    icon: 'Coffee',
    color: itemTypeColors.coffee.hex,
    
    fields: [
      {
        key: 'name',
        label: 'Name',
        type: 'text',
        required: true,
        maxLength: 200,
        placeholder: 'e.g., Brewmance, Joyeux Roger',
      },
      {
        key: 'roaster',
        label: 'Roaster',
        type: 'text',
        required: true,
        maxLength: 200,
        placeholder: 'e.g., ZAB Café, Café Saint-Henri',
      },
      {
        key: 'country',
        label: 'Country',
        type: 'text',
        required: false,
        maxLength: 100,
        placeholder: 'e.g., Brésil, Éthiopie, Colombie',
      },
      {
        key: 'region',
        label: 'Region',
        type: 'text',
        required: false,
        maxLength: 100,
        placeholder: 'e.g., Yirgacheffe, Huila',
      },
      {
        key: 'farm',
        label: 'Farm',
        type: 'text',
        required: false,
        maxLength: 200,
        placeholder: 'e.g., Finca El Paraíso',
      },
      {
        key: 'altitude',
        label: 'Altitude',
        type: 'text',
        required: false,
        maxLength: 50,
        placeholder: 'e.g., 1200-1600m',
      },
      {
        key: 'species',
        label: 'Species',
        type: 'select',
        required: false,
        options: [
          { value: 'Arabica', label: 'Arabica' },
          { value: 'Robusta', label: 'Robusta' },
          { value: 'Libérica', label: 'Libérica' },
          { value: 'Excelsa', label: 'Excelsa' },
        ],
      },
      {
        key: 'variety',
        label: 'Variety',
        type: 'text',
        required: false,
        maxLength: 100,
        placeholder: 'e.g., Bourbon, Caturra, Geisha',
      },
      {
        key: 'processing_method',
        label: 'Processing Method',
        type: 'select',
        required: false,
        options: [
          { value: 'Lavé', label: 'Lavé (Washed)' },
          { value: 'Nature', label: 'Nature (Natural)' },
          { value: 'Honey', label: 'Honey' },
          { value: 'Anaérobie', label: 'Anaérobie (Anaerobic)' },
          { value: 'Macération Carbonique', label: 'Macération Carbonique' },
          { value: 'Décortiqué Humide', label: 'Décortiqué Humide (Wet-Hulled)' },
          { value: 'Nature Dépulpé', label: 'Nature Dépulpé (Pulped Natural)' },
        ],
      },
      {
        key: 'decaffeinated',
        label: 'Decaffeinated',
        type: 'checkbox',
        required: false,
      },
      {
        key: 'roast_level',
        label: 'Roast Level',
        type: 'select',
        required: false,
        options: [
          { value: 'Pâle', label: 'Pâle (Light)' },
          { value: 'Moyen', label: 'Moyen (Medium)' },
          { value: 'Foncé', label: 'Foncé (Dark)' },
        ],
      },
      {
        key: 'tasting_notes',
        label: 'Tasting Notes',
        type: 'text',
        required: false,
        maxLength: 500,
        placeholder: 'e.g., chocolat, fruits rouges, floral',
        helperText: 'Comma-separated flavor notes',
      },
      {
        key: 'acidity',
        label: 'Acidity',
        type: 'select',
        required: false,
        options: [
          { value: 'Faible', label: 'Faible (Low)' },
          { value: 'Moyen', label: 'Moyen (Medium)' },
          { value: 'Élevé', label: 'Élevé (High)' },
        ],
      },
      {
        key: 'body',
        label: 'Body',
        type: 'select',
        required: false,
        options: [
          { value: 'Faible', label: 'Faible (Light)' },
          { value: 'Moyen', label: 'Moyen (Medium)' },
          { value: 'Élevé', label: 'Élevé (Full)' },
        ],
      },
      {
        key: 'sweetness',
        label: 'Sweetness',
        type: 'select',
        required: false,
        options: [
          { value: 'Faible', label: 'Faible (Low)' },
          { value: 'Moyen', label: 'Moyen (Medium)' },
          { value: 'Élevé', label: 'Élevé (High)' },
        ],
      },
      {
        key: 'organic',
        label: 'Organic',
        type: 'checkbox',
        required: false,
      },
      {
        key: 'fair_trade',
        label: 'Fair Trade',
        type: 'checkbox',
        required: false,
      },
      {
        key: 'description',
        label: 'Description',
        type: 'textarea',
        required: false,
        maxLength: 1000,
        placeholder: 'Optional description...',
      },
    ],
    
    table: {
      columns: ['name', 'roaster', 'country', 'roast_level', 'processing_method'],
      searchableFields: ['name', 'roaster', 'country', 'region', 'variety', 'description'],
      defaultSort: 'name',
      sortOrder: 'asc',
    },
    
    apiEndpoints: {
      list: '/api/coffee/all',
      detail: (id: number) => `/api/coffee/${id}`,
      deleteImpact: (id: number) => `/admin/coffee/${id}/delete-impact`,
      delete: (id: number) => `/admin/coffee/${id}`,
      seed: '/admin/coffee/seed',
      validate: '/admin/coffee/validate',
    },
  },
};

/**
 * Get configuration for a specific item type
 */
export function getItemTypeConfig(itemType: string): ItemTypeConfig {
  const config = itemTypesConfig[itemType];
  if (!config) {
    throw new Error(`Unknown item type: ${itemType}`);
  }
  return config;
}

/**
 * Get all registered item types
 */
export function getAllItemTypes(): string[] {
  return Object.keys(itemTypesConfig);
}

/**
 * Check if an item type exists
 */
export function isValidItemType(itemType: string): boolean {
  return itemType in itemTypesConfig;
}

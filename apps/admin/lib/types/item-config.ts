import { LucideIcon } from 'lucide-react';

/**
 * Field configuration for item types
 */
export type FieldType = 'text' | 'textarea' | 'number' | 'select' | 'checkbox';

export interface FieldConfig {
  key: string;
  label: string;
  type: FieldType;
  required: boolean;
  maxLength?: number;
  minLength?: number;
  min?: number;
  max?: number;
  placeholder?: string;
  helperText?: string;
  options?: { value: string; label: string }[]; // For select fields
}

/**
 * Table configuration
 */
export interface TableConfig {
  columns: string[]; // Field keys to display as columns
  searchableFields: string[]; // Fields to include in search
  defaultSort?: string; // Default sort column
  sortOrder?: 'asc' | 'desc';
}

/**
 * API endpoint configuration
 */
export interface ApiEndpointConfig {
  list: string;
  detail: (id: number) => string;
  deleteImpact: (id: number) => string;
  delete: (id: number) => string;
  seed: string;
  validate?: string;
}

/**
 * Complete item type configuration
 */
export interface ItemTypeConfig {
  name: string; // Unique identifier (e.g., 'cheese', 'wine')
  labels: {
    singular: string; // Display name singular (e.g., 'Cheese')
    plural: string; // Display name plural (e.g., 'Cheeses')
  };
  icon: string; // Lucide icon name (e.g., 'ChefHat')
  color: string; // Hex color for visual identification (e.g., '#673AB7')
  fields: FieldConfig[];
  table: TableConfig;
  apiEndpoints: ApiEndpointConfig;
}

/**
 * Registry of all item types
 */
export type ItemTypeRegistry = Record<string, ItemTypeConfig>;

/**
 * Base item interface that all items must implement
 */
export interface BaseItem {
  id: number;
  name: string;
  image_url?: string | null; // Optional image URL
  created_at: string;
  updated_at: string;
  [key: string]: any; // Allow additional fields
}

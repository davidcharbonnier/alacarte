import { apiClient } from './client';
import { getItemTypeConfig } from '../config/item-types';
import type { BaseItem } from '../types/item-config';
import type { DeleteImpact } from '../types/api';

/**
 * Transform backend GORM format to frontend JavaScript conventions
 */
function transformItem(backendItem: any): any {
  const transformed: any = {};
  
  // Handle GORM standard fields
  if (backendItem.ID !== undefined) transformed.id = backendItem.ID;
  if (backendItem.CreatedAt) transformed.created_at = backendItem.CreatedAt;
  if (backendItem.UpdatedAt) transformed.updated_at = backendItem.UpdatedAt;
  if (backendItem.DeletedAt) transformed.deleted_at = backendItem.DeletedAt;
  
  // Copy all other fields as-is (they're already lowercase in Go)
  Object.keys(backendItem).forEach(key => {
    if (!['ID', 'CreatedAt', 'UpdatedAt', 'DeletedAt'].includes(key)) {
      transformed[key] = backendItem[key];
    }
  });
  
  return transformed;
}

/**
 * Generic API client factory
 * Creates type-safe API client for any item type
 */
export function createItemApi<T extends BaseItem>(itemType: string) {
  const config = getItemTypeConfig(itemType);
  
  return {
    /**
     * Get all items of this type
     */
    getAll: async (): Promise<T[]> => {
      const data = await apiClient.get<any[]>(config.apiEndpoints.list);
      return data.map(transformItem) as T[];
    },

    /**
     * Get single item by ID
     */
    getById: async (id: number): Promise<T> => {
      const data = await apiClient.get<any>(config.apiEndpoints.detail(id));
      return transformItem(data) as T;
    },

    /**
     * Get delete impact assessment
     */
    getDeleteImpact: async (id: number): Promise<DeleteImpact> => {
      return apiClient.get<DeleteImpact>(config.apiEndpoints.deleteImpact(id));
    },

    /**
     * Delete item
     */
    delete: async (id: number): Promise<void> => {
      return apiClient.delete<void>(config.apiEndpoints.delete(id));
    },

    /**
     * Seed items from URL
     */
    seed: async (url: string): Promise<{ added: number; skipped: number; errors: string[] }> => {
      return apiClient.post(config.apiEndpoints.seed, { url });
    },

    /**
     * Seed items from direct data upload
     */
    seedData: async (data: any): Promise<{ added: number; skipped: number; errors: string[] }> => {
      return apiClient.post(config.apiEndpoints.seed, { data });
    },

    /**
     * Validate seed data from URL
     */
    validate: async (url: string): Promise<{ valid: boolean; errors: string[] }> => {
      if (config.apiEndpoints.validate) {
        return apiClient.post(config.apiEndpoints.validate, { url });
      }
      
      // If no validate endpoint, just return valid
      return { valid: true, errors: [] };
    },

    /**
     * Validate seed data from direct upload
     */
    validateData: async (data: any): Promise<{ valid: boolean; errors: string[] }> => {
      if (config.apiEndpoints.validate) {
        return apiClient.post(config.apiEndpoints.validate, { data });
      }
      
      // If no validate endpoint, just return valid
      return { valid: true, errors: [] };
    },
  };
}

/**
 * Get API client for a specific item type
 */
export function getItemApi<T extends BaseItem>(itemType: string) {
  return createItemApi<T>(itemType);
}

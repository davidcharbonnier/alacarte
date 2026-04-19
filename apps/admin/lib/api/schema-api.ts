import { apiClient } from './client';
import type {
  ItemTypeSchema,
  SchemaField,
  CreateSchemaRequest,
  UpdateSchemaRequest,
  SchemaListResponse,
  SchemaDetailResponse,
} from '../types/schema';

export const schemaApi = {
  list: async (includeInactive = false): Promise<ItemTypeSchema[]> => {
    const url = includeInactive ? '/api/schemas?include_inactive=true' : '/api/schemas';
    const response = await apiClient.get<SchemaListResponse>(url);
    return response.schemas || [];
  },

  get: async (type: string): Promise<{ schema: SchemaDetailResponse; fields: SchemaField[] }> => {
    const response = await apiClient.get<SchemaDetailResponse>(`/api/schemas/${type}`);
    return {
      schema: response,
      fields: response.fields || [],
    };
  },

  create: async (data: CreateSchemaRequest): Promise<ItemTypeSchema> => {
    const response = await apiClient.post<ItemTypeSchema>('/admin/schemas', data);
    return response;
  },

  update: async (type: string, data: UpdateSchemaRequest): Promise<SchemaDetailResponse> => {
    const response = await apiClient.put<{ message: string; schema: SchemaDetailResponse }>(`/admin/schemas/${type}`, data);
    return response.schema;
  },

  delete: async (type: string): Promise<void> => {
    return apiClient.delete(`/admin/schemas/${type}`);
  },

  getVersion: async (type: string, version: number): Promise<{ schema: any; fields: SchemaField[] }> => {
    const response = await apiClient.get<any>(`/admin/schemas/${type}/versions/${version}`);
    return {
      schema: response,
      fields: response.fields || [],
    };
  },
};

export const dynamicItemApi = {
  list: async (type: string, params?: { page?: number; page_size?: number; search?: string }): Promise<{ items: any[]; total: number }> => {
    const searchParams = new URLSearchParams();
    if (params?.page) searchParams.set('page', params.page.toString());
    if (params?.page_size) searchParams.set('page_size', params.page_size.toString());
    if (params?.search) searchParams.set('search', params.search);
    
    const queryString = searchParams.toString();
    const url = `/api/items/${type}${queryString ? `?${queryString}` : ''}`;
    return apiClient.get<{ items: any[]; total: number }>(url);
  },

  get: async (type: string, id: number): Promise<any> => {
    return apiClient.get(`/api/items/${type}/${id}`);
  },

  create: async (type: string, data: any): Promise<any> => {
    return apiClient.post(`/api/items/${type}`, data);
  },

  update: async (type: string, id: number, data: any): Promise<any> => {
    return apiClient.put(`/api/items/${type}/${id}`, data);
  },

  delete: async (type: string, id: number): Promise<void> => {
    return apiClient.delete(`/api/items/${type}/${id}`);
  },

  getDeleteImpact: async (type: string, id: number): Promise<any> => {
    return apiClient.get(`/admin/items/${type}/${id}/delete-impact`);
  },
};
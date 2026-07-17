import { apiClient } from './client';
import type { User } from '../types/user';
import type { DeleteImpact } from '../types/api';

function transformUser(backendUser: any): User {
  return {
    id: backendUser.ID,
    email: backendUser.email,
    display_name: backendUser.display_name,
    full_name: backendUser.full_name,
    avatar: backendUser.avatar,
    google_id: backendUser.google_id,
    discoverable: backendUser.discoverable,
    is_admin: backendUser.is_admin,
    created_at: backendUser.CreatedAt,
    updated_at: backendUser.UpdatedAt,
    last_login_at: backendUser.last_login_at,
  };
}

export const userApi = {
  getAll: async (): Promise<User[]> => {
    const data = await apiClient.get<any[]>('/admin/users/all');
    return data.map(transformUser);
  },
  getById: async (id: number): Promise<User> => {
    const data = await apiClient.get<any>(`/admin/user/${id}`);
    return transformUser(data);
  },
  getDeleteImpact: (id: number): Promise<DeleteImpact> =>
    apiClient.get<DeleteImpact>(`/admin/user/${id}/delete-impact`),
  delete: (id: number): Promise<void> => apiClient.delete<void>(`/admin/user/${id}`),
  promote: async (id: number) => {
    const response = await apiClient.patch<{ message: string; user: any }>(`/admin/user/${id}/promote`, {});
    return { message: response.message, user: response.user as any };
  },
  demote: async (id: number) => {
    const response = await apiClient.patch<{ message: string; user: any }>(`/admin/user/${id}/demote`, {});
    return { message: response.message, user: response.user as any };
  },
  getCurrentUser: async (): Promise<User> => {
    const data = await apiClient.get<any>('/api/user/me');
    return transformUser(data);
  },
};

// Common API response types
export interface ApiResponse<T> {
  data: T;
  message?: string;
}

export interface ApiError {
  error: string;
  message?: string;
  details?: Record<string, string[]>;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  page_size: number;
}

export interface DeleteImpact {
  can_delete: boolean;
  warnings: string[];
  impact: {
    ratings_count: number;
    users_affected: number;
    sharings_count: number;
    affected_users: AffectedUserInfo[];
  };
}

export interface AffectedUserInfo {
  id: number;
  display_name: string;
  ratings_count: number;
}

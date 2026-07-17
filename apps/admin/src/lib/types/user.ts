export interface User {
  id: number;
  email: string;
  display_name: string;
  full_name: string;
  avatar: string;
  google_id: string;
  discoverable: boolean;
  is_admin: boolean;
  created_at: string;
  updated_at: string;
  last_login_at: string;
}

export interface AuthTokens {
  access_token: string;
  refresh_token?: string;
  expires_in?: number;
}

export interface AuthResponse {
  token: string;
  user: User;
  message?: string;
}

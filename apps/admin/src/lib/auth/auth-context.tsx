import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import { jwtDecode } from 'jwt-decode';
import { apiClient, getRouter, JWT_STORAGE_KEY } from '../api/client';
import type { User } from '../types/user';

interface JwtPayload {
  sub: string;
  email: string;
  exp: number;
  // Other backend-defined fields are present but not used by the SPA
}

interface AuthContextValue {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  isAdmin: boolean;
  signInWithGoogle: (idToken: string, accessToken?: string) => Promise<void>;
  checkAdmin: () => Promise<boolean>;
  signOut: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

// ponytail: rebuild a User from a JWT payload. Mirrors the backend's GORM-to-JSON
// claim shape (email, sub = user id).
function userFromJwt(token: string): User | null {
  try {
    const payload = jwtDecode<JwtPayload & Record<string, any>>(token);
    if (!payload?.exp || payload.exp * 1000 < Date.now()) return null;
    return {
      id: Number(payload.sub ?? payload.user_id ?? payload.ID ?? 0),
      email: payload.email ?? '',
      display_name: payload.display_name ?? payload.name ?? payload.email ?? '',
      full_name: payload.full_name ?? payload.name ?? '',
      avatar: payload.avatar ?? payload.picture ?? '',
      google_id: payload.google_id ?? '',
      discoverable: Boolean(payload.discoverable),
      is_admin: Boolean(payload.is_admin),
      created_at: payload.created_at ?? '',
      updated_at: payload.updated_at ?? '',
      last_login_at: payload.last_login_at ?? '',
    };
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(() => {
    try {
      return sessionStorage.getItem(JWT_STORAGE_KEY);
    } catch {
      return null;
    }
  });
  const [user, setUser] = useState<User | null>(() => {
    try {
      const t = sessionStorage.getItem(JWT_STORAGE_KEY);
      return t ? userFromJwt(t) : null;
    } catch {
      return null;
    }
  });
  const [isLoading, setIsLoading] = useState(false);

  const signInWithGoogle = useCallback(async (idToken: string, accessToken?: string) => {
    setIsLoading(true);
    try {
      const response = await apiClient.post<{ token: string; user: User }>('/auth/google', {
        id_token: idToken,
        access_token: accessToken,
      });
      try {
        sessionStorage.setItem(JWT_STORAGE_KEY, response.token);
      } catch {
        // ignore
      }
      setToken(response.token);
      setUser(response.user);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const checkAdmin = useCallback(async (): Promise<boolean> => {
    try {
      const { is_admin } = await apiClient.get<{ is_admin: boolean }>('/api/auth/check-admin');
      return Boolean(is_admin);
    } catch {
      return false;
    }
  }, []);

  const signOut = useCallback(() => {
    try {
      sessionStorage.removeItem(JWT_STORAGE_KEY);
    } catch {
      // ignore
    }
    setToken(null);
    setUser(null);
    const router = getRouter();
    if (router) {
      router.navigate({ to: '/login' });
    } else if (typeof window !== 'undefined') {
      window.location.href = '/login';
    }
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      token,
      isLoading,
      isAdmin: Boolean(user?.is_admin),
      signInWithGoogle,
      checkAdmin,
      signOut,
    }),
    [user, token, isLoading, signInWithGoogle, checkAdmin, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

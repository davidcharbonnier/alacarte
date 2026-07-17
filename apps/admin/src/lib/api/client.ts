import axios, { type AxiosInstance, type AxiosRequestConfig } from 'axios';
import type { AnyRouter } from '@tanstack/react-router';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

export const JWT_STORAGE_KEY = 'jwt_token';

// ponytail: hold a router reference so the 401 interceptor can do SPA navigation
// without a full page reload. Set once at app boot.
let routerRef: AnyRouter | null | undefined = undefined;
export function setRouter(router: AnyRouter | null) {
  routerRef = router;
}
export function getRouter(): AnyRouter | null | undefined {
  return routerRef;
}

function readToken(): string | null {
  try {
    return sessionStorage.getItem(JWT_STORAGE_KEY);
  } catch {
    return null;
  }
}

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: API_URL,
      headers: {
        'Content-Type': 'application/json',
        // ponytail: the backend sets Cache-Control: public, max-age=300 on
        // /api/schemas/:type (for the Flutter client). Without these headers
        // the browser serves a 5-minute-stale response on every refetch,
        // overwriting the fresh cache the editor's save just wrote.
        // no-cache + ETag revalidation: the server still returns 304 (no body)
        // when nothing changed, so this is cheap.
        'Cache-Control': 'no-cache',
        Pragma: 'no-cache',
      },
    });

    // ponytail: request interceptor reads JWT from sessionStorage (replaces
    // NextAuth's getSession() interceptor).
    this.client.interceptors.request.use(
      (config) => {
        const token = readToken();
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        // Defensive: some HTTP clients strip default headers per-request.
        config.headers['Cache-Control'] = 'no-cache';
        config.headers['Pragma'] = 'no-cache';
        return config;
      },
      (error) => Promise.reject(error),
    );

    this.client.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          try {
            sessionStorage.removeItem(JWT_STORAGE_KEY);
          } catch {
            // ignore
          }
          if (routerRef) {
            routerRef.navigate({ to: '/login' });
          } else if (typeof window !== 'undefined') {
            // ponytail: fallback before router mounts. Acceptable since
            // 401 during boot is a cold-start race; login page is the same target.
            window.location.href = '/login';
          }
        }
        return Promise.reject(error);
      },
    );
  }

  get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return this.client.get<T>(url, config).then((r) => r.data);
  }
  post<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    return this.client.post<T>(url, data, config).then((r) => r.data);
  }
  put<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    return this.client.put<T>(url, data, config).then((r) => r.data);
  }
  patch<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    return this.client.patch<T>(url, data, config).then((r) => r.data);
  }
  delete<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return this.client.delete<T>(url, config).then((r) => r.data as T);
  }
  postFormData<T>(url: string, formData: FormData, config?: AxiosRequestConfig): Promise<T> {
    return this.client
      .post<T>(url, formData, {
        ...config,
        headers: {
          ...config?.headers,
          'Content-Type': 'multipart/form-data',
        },
      })
      .then((r) => r.data);
  }
}

export const apiClient = new ApiClient();
export { API_URL };

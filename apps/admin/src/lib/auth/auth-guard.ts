import { redirect } from '@tanstack/react-router';

// ponytail: redirect to /login when no JWT. Used as TanStack Router beforeLoad.
export function requireAuth() {
  try {
    const token = sessionStorage.getItem('jwt_token');
    if (!token) {
      throw redirect({ to: '/login' });
    }
  } catch (err) {
    if ((err as any)?.status === 302 || (err as any)?.isRedirect) throw err;
    throw redirect({ to: '/login' });
  }
}

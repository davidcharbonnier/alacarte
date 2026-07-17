import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { GoogleOAuthProvider } from '@react-oauth/google';
import { RouterProvider } from '@tanstack/react-router';
import { ThemeModeProvider } from './theme-context';
import { AuthProvider } from './lib/auth/auth-context';
import { SchemaProvider } from './lib/context/schema-context';
import { router } from './router';
import { setRouter } from './lib/api/client';
import './main.css';

const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID || '';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,
      refetchOnWindowFocus: false,
    },
  },
});

setRouter(router);

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ThemeModeProvider>
      <GoogleOAuthProvider clientId={GOOGLE_CLIENT_ID}>
        <QueryClientProvider client={queryClient}>
          <AuthProvider>
            <SchemaProvider>
              <RouterProvider router={router} />
            </SchemaProvider>
          </AuthProvider>
        </QueryClientProvider>
      </GoogleOAuthProvider>
    </ThemeModeProvider>
  </StrictMode>,
);

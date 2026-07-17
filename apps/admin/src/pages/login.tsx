import { Alert, Box, Card, CardContent, Stack, Typography } from '@mui/material';
import ErrorOutline from '@mui/icons-material/ErrorOutline';
import { GoogleLogin, type CredentialResponse } from '@react-oauth/google';
import { useState } from 'react';
import { useNavigate } from '@tanstack/react-router';
import { useAuth } from '../lib/auth/auth-context';

// ponytail: GoogleLogin gives us the JWT id_token directly via `credential`,
// which is exactly what the backend /auth/google endpoint needs. Mirror the
// Flutter client payload shape: {id_token, access_token}. id_token alone is
// sufficient for backend verification; access_token is included for parity.
export function LoginPage() {
  const { signInWithGoogle, checkAdmin, isLoading } = useAuth();
  const navigate = useNavigate();
  const [error, setError] = useState<string | null>(null);

  const clientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;
  if (!clientId || clientId === 'your_google_web_client_id_here') {
    return (
      <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', bgcolor: 'background' }}>
        <Card sx={{ maxWidth: 520, width: '100%' }}>
          <CardContent sx={{ p: 4 }}>
            <Stack spacing={2}>
              <Alert severity="error" icon={<ErrorOutline />}>
                <Typography fontWeight={500}>Google OAuth is not configured</Typography>
                <Typography variant="body2">
                  <code>VITE_GOOGLE_CLIENT_ID</code> is missing or still set to the placeholder.
                </Typography>
              </Alert>
              <Typography variant="body2" color="onSurfaceVariant">
                1. Create a <strong>Web application</strong> OAuth client in Google Cloud Console.
                <br />
                2. Add <code>http://localhost:3000</code> to <em>Authorized JavaScript origins</em>.
                <br />
                3. Put the client ID in <code>apps/admin/.env</code> as <code>VITE_GOOGLE_CLIENT_ID=...</code>.
                <br />
                4. Restart <code>npm run dev</code> (Vite loads env at startup).
              </Typography>
            </Stack>
          </CardContent>
        </Card>
      </Box>
    );
  }

  const handleSuccess = async (response: CredentialResponse) => {
    setError(null);
    if (!response.credential) {
      setError('Google did not return an id_token. Please try again.');
      return;
    }
    try {
      await signInWithGoogle(response.credential, undefined);
      const isAdmin = await checkAdmin();
      if (!isAdmin) {
        navigate({ to: '/access-denied' });
        return;
      }
      navigate({ to: '/' });
    } catch (err) {
      setError((err as Error).message || 'Authentication failed');
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', bgcolor: 'background' }}>
      <Card sx={{ maxWidth: 420, width: '100%' }}>
        <CardContent sx={{ p: 4 }}>
          <Stack spacing={3} alignItems="center" textAlign="center">
            <Box>
              <Typography variant="headlineSmall" component="h1" sx={{ mb: 0.5 }}>
                À la carte Admin
              </Typography>
              <Typography variant="bodyMedium" color="onSurfaceVariant">
                Sign in with your Google account to continue
              </Typography>
            </Box>
            {error && (
              <Alert severity="error" icon={<ErrorOutline />} sx={{ width: '100%' }}>
                {error}
              </Alert>
            )}
            <Box sx={{ opacity: isLoading ? 0.5 : 1 }}>
              <GoogleLogin
                onSuccess={handleSuccess}
                onError={() => setError('Google sign-in failed. Please try again.')}
                useOneTap={false}
                width="320"
              />
            </Box>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}

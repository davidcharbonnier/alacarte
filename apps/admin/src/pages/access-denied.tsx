import { Alert, Box, Button, Card, CardContent, Stack, Typography } from '@mui/material';
import Block from '@mui/icons-material/Block';
import { useNavigate } from '@tanstack/react-router';
import { useAuth } from '../lib/auth/auth-context';

export function AccessDeniedPage() {
  const navigate = useNavigate();
  const { signOut } = useAuth();

  return (
    <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', bgcolor: 'background' }}>
      <Card sx={{ maxWidth: 460, width: '100%' }}>
        <CardContent sx={{ p: 4 }}>
          <Stack spacing={3} alignItems="center" textAlign="center">
            <Box
              sx={{
                width: 72,
                height: 72,
                borderRadius: '20px',
                bgcolor: 'errorContainer',
                color: 'onErrorContainer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Block sx={{ fontSize: 36 }} />
            </Box>
            <Box>
              <Typography variant="headlineSmall" component="h1" sx={{ mb: 1 }}>
                Access denied
              </Typography>
              <Typography variant="bodyMedium" color="onSurfaceVariant">
                Your account does not have administrator privileges. Contact an administrator if you
                believe this is an error.
              </Typography>
            </Box>
            <Stack direction="row" spacing={1.5} sx={{ width: '100%' }}>
              <Button variant="outlined" onClick={() => signOut()} fullWidth>
                Sign out
              </Button>
              <Button variant="contained" onClick={() => navigate({ to: '/login' })} fullWidth>
                Back to sign in
              </Button>
            </Stack>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}

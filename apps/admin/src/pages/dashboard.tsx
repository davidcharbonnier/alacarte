import { Box, Stack, Typography } from '@mui/material';
import { useAuth } from '../lib/auth/auth-context';
import { DashboardStats } from '../components/dashboard/dashboard-stats';

export function DashboardPage() {
  const { user } = useAuth();

  return (
    <Stack spacing={4}>
      <Box>
        <Typography variant="headlineMedium" component="h1" sx={{ mb: 0.5 }}>
          {user?.display_name ? `Welcome back, ${user.display_name}` : 'Dashboard'}
        </Typography>
        <Typography variant="bodyLarge" color="onSurfaceVariant">
          Manage items, users, and schemas
        </Typography>
      </Box>
      <DashboardStats />
    </Stack>
  );
}

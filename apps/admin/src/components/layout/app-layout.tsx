import { Box } from '@mui/material';
import { Outlet } from '@tanstack/react-router';
import { AppShell } from './app-shell';

export function AppLayout() {
  return (
    <AppShell>
      <Box sx={{ p: 3 }}>
        <Outlet />
      </Box>
    </AppShell>
  );
}

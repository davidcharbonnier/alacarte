import { useState, type ReactNode } from 'react';
import {
  AppBar,
  Avatar,
  Box,
  Divider,
  Drawer,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem,
  Stack,
  Toolbar,
  Tooltip,
  Typography,
  useTheme,
} from '@mui/material';
import DarkMode from '@mui/icons-material/DarkMode';
import LightMode from '@mui/icons-material/LightMode';
import Shield from '@mui/icons-material/Shield';
import People from '@mui/icons-material/People';
import Home from '@mui/icons-material/Home';
import Logout from '@mui/icons-material/Logout';
import AdminPanelSettings from '@mui/icons-material/AdminPanelSettings';
import { Link, useRouterState } from '@tanstack/react-router';
import { useSchemaContext } from '../../lib/context/schema-context';
import { useAuth } from '../../lib/auth/auth-context';
import { useThemeMode } from '../../theme-context';
import { resolveIcon } from '../../lib/icons/icon-registry';

// M3 NavigationDrawer width: 240px for compact, 360px for medium. Use 240.
const DRAWER_WIDTH = 240;

export function AppShell({ children }: { children: ReactNode }) {
  const theme = useTheme();
  const { user, signOut } = useAuth();
  const { mode, toggle } = useThemeMode();
  const { schemas } = useSchemaContext();
  const { location } = useRouterState();
  const [userAnchor, setUserAnchor] = useState<HTMLElement | null>(null);

  const isActive = (href: string) =>
    location.pathname === href || (href !== '/' && location.pathname.startsWith(href));

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      {/* M3 TopAppBar (Medium) */}
      <AppBar
        position="fixed"
        sx={{
          zIndex: theme.zIndex.drawer + 1,
          bgcolor: 'surfaceContainer',
          color: 'onSurface',
        }}
      >
        <Toolbar sx={{ minHeight: 64 }}>
          <Stack direction="row" alignItems="center" spacing={1.5} sx={{ minWidth: DRAWER_WIDTH - 24, pr: 3 }}>
            <Box
              sx={{
                width: 32,
                height: 32,
                borderRadius: '12px',
                bgcolor: 'primaryContainer',
                color: 'onPrimaryContainer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Shield fontSize="small" />
            </Box>
            <Typography variant="titleMedium" fontWeight={500}>
              À la carte Admin
            </Typography>
          </Stack>

          <Box sx={{ flexGrow: 1 }} />

          <Stack direction="row" spacing={1}>
            <Tooltip title={`Switch to ${mode === 'light' ? 'dark' : 'light'} mode`}>
              <IconButton onClick={toggle} color="inherit">
                {mode === 'light' ? <DarkMode /> : <LightMode />}
              </IconButton>
            </Tooltip>
            <Tooltip title={user?.email || 'Account'}>
              <IconButton onClick={(e) => setUserAnchor(e.currentTarget)} sx={{ p: 0.5 }}>
                <Avatar
                  src={user?.avatar || undefined}
                  sx={{ width: 36, height: 36, bgcolor: 'primaryContainer', color: 'onPrimaryContainer' }}
                >
                  {user?.display_name?.[0]?.toUpperCase() || user?.email?.[0]?.toUpperCase() || 'A'}
                </Avatar>
              </IconButton>
            </Tooltip>
          </Stack>

          <Menu anchorEl={userAnchor} open={Boolean(userAnchor)} onClose={() => setUserAnchor(null)}>
            <MenuItem disabled>
              <Stack>
                <Typography variant="body2">{user?.display_name || user?.email || 'Admin'}</Typography>
                {user?.email && (
                  <Typography variant="caption" color="text.secondary">
                    {user.email}
                  </Typography>
                )}
              </Stack>
            </MenuItem>
            {user?.is_admin && (
              <MenuItem disabled>
                <AdminPanelSettings fontSize="small" sx={{ mr: 1, color: 'primary' }} />
                <Typography variant="body2">Administrator</Typography>
              </MenuItem>
            )}
            <Divider />
            {user?.id && (
              <MenuItem
                onClick={() => {
                  setUserAnchor(null);
                  window.location.href = `/users/${user.id}`;
                }}
              >
                My Account
              </MenuItem>
            )}
            <MenuItem
              onClick={() => {
                setUserAnchor(null);
                signOut();
              }}
            >
              <Logout fontSize="small" sx={{ mr: 1 }} />
              Sign out
            </MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>

      {/* M3 Permanent NavigationDrawer */}
      <Drawer
        variant="permanent"
        sx={{
          width: DRAWER_WIDTH,
          flexShrink: 0,
          '& .MuiDrawer-paper': {
            width: DRAWER_WIDTH,
            boxSizing: 'border-box',
            bgcolor: 'surfaceContainerLow',
            borderRight: 1,
            borderColor: 'outlineVariant',
          },
        }}
      >
        <Toolbar sx={{ minHeight: 64 }} />

        <List sx={{ pt: 1, px: 1.5 }} disablePadding>
          <DrawerItem
            href="/"
            icon={<Home />}
            label="Dashboard"
            active={isActive('/')}
          />
        </List>

        <Typography
          variant="labelSmall"
          sx={{ px: 3, pt: 4, pb: 1, color: 'onSurfaceVariant', display: 'block' }}
        >
          Item types
        </Typography>
        <List sx={{ px: 1.5 }} disablePadding>
          {schemas.map((schema) => {
            const Icon = resolveIcon(schema.icon);
            const href = `/items/${schema.name}`;
            return (
              <DrawerItem
                key={schema.name}
                href={href}
                icon={<Icon />}
                label={schema.plural_name}
                active={isActive(href)}
              />
            );
          })}
        </List>

        <Box sx={{ flexGrow: 1 }} />

        <List sx={{ p: 1.5 }} disablePadding>
          <DrawerItem
            href="/users"
            icon={<People />}
            label="Users"
            active={isActive('/users')}
          />
          <DrawerItem
            href="/schemas"
            icon={<Shield />}
            label="Schemas"
            active={isActive('/schemas')}
          />
        </List>
      </Drawer>

      {/* Main content */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          minHeight: '100vh',
          bgcolor: 'background',
        }}
      >
        <Toolbar sx={{ minHeight: 64 }} />
        {children}
      </Box>
    </Box>
  );
}

function DrawerItem({
  href,
  icon,
  label,
  active,
}: {
  href: string;
  icon: ReactNode;
  label: string;
  active: boolean;
}) {
  return (
    <ListItem disablePadding sx={{ mb: 0.25 }}>
      <ListItemButton
        component={Link}
        to={href}
        selected={active}
        sx={{
          borderRadius: 28,
          minHeight: 48,
          px: 2,
          '&.Mui-selected': {
            bgcolor: 'secondaryContainer',
            color: 'onSecondaryContainer',
            '& .MuiListItemIcon-root': { color: 'onSecondaryContainer' },
            '&:hover': { bgcolor: 'secondaryContainer' },
          },
        }}
      >
        <ListItemIcon
          sx={{
            minWidth: 40,
            color: active ? 'onSecondaryContainer' : 'onSurfaceVariant',
          }}
        >
          {icon}
        </ListItemIcon>
        <ListItemText
          primary={label}
          primaryTypographyProps={{
            fontWeight: active ? 600 : 500,
            fontSize: '0.875rem',
          }}
        />
      </ListItemButton>
    </ListItem>
  );
}

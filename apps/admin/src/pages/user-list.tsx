import {
  Avatar,
  Box,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  IconButton,
  List,
  ListItem,
  ListItemAvatar,
  ListItemButton,
  ListItemText,
  Stack,
  Typography,
} from '@mui/material';
import Shield from '@mui/icons-material/Shield';
import Person from '@mui/icons-material/Person';
import CalendarToday from '@mui/icons-material/CalendarToday';
import Email from '@mui/icons-material/Email';
import ArrowForward from '@mui/icons-material/ArrowForward';
import { useQuery } from '@tanstack/react-query';
import { Link } from '@tanstack/react-router';
import { formatDistanceToNow } from 'date-fns';
import { userApi } from '../lib/api/users';

export function UserListPage() {
  const { data: users, isLoading, error } = useQuery({
    queryKey: ['users', 'list'],
    queryFn: userApi.getAll,
  });

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
        <CircularProgress />
      </Box>
    );
  }
  if (error) {
    return <Typography color="error">Failed to load users: {(error as Error).message}</Typography>;
  }

  const adminCount = users?.filter((u) => u.is_admin).length || 0;
  const regularCount = (users?.length || 0) - adminCount;

  return (
    <Stack spacing={3}>
      <Box>
        <Typography variant="headlineSmall" component="h1" sx={{ mb: 0.5 }}>
          Users
        </Typography>
        <Typography variant="bodyMedium" color="onSurfaceVariant">
          {users?.length || 0} total ({adminCount} admins · {regularCount} regular)
        </Typography>
      </Box>

      <Card>
        <List disablePadding>
          {users && users.length > 0 ? (
            users.map((user, index) => (
              <Box key={user.id}>
                {index > 0 && <Box sx={{ borderTop: 1, borderColor: 'outlineVariant' }} />}
                <ListItem disablePadding>
                  <ListItemButton component={Link} to={`/users/${user.id}`} sx={{ py: 2, px: 3 }}>
                    <ListItemAvatar>
                      <Avatar src={user.avatar} sx={{ bgcolor: 'primaryContainer', color: 'onPrimaryContainer' }}>
                        <Person />
                      </Avatar>
                    </ListItemAvatar>
                    <ListItemText
                      primary={
                        <Stack direction="row" spacing={1} alignItems="center">
                          <Typography variant="bodyLarge" fontWeight={500}>
                            {user.display_name || user.full_name}
                          </Typography>
                          {user.is_admin && (
                            <Chip size="small" label="Admin" icon={<Shield />} color="primary" variant="filled" />
                          )}
                        </Stack>
                      }
                      secondary={
                        <Stack spacing={0.25} sx={{ mt: 0.5 }}>
                          <Stack direction="row" spacing={0.75} alignItems="center">
                            <Email sx={{ fontSize: 14, color: 'onSurfaceVariant' }} />
                            <Typography variant="bodySmall" color="onSurfaceVariant">
                              {user.email}
                            </Typography>
                          </Stack>
                          <Stack direction="row" spacing={0.75} alignItems="center">
                            <CalendarToday sx={{ fontSize: 14, color: 'onSurfaceVariant' }} />
                            <Typography variant="bodySmall" color="onSurfaceVariant">
                              Last login {formatDistanceToNow(new Date(user.last_login_at), { addSuffix: true })}
                            </Typography>
                          </Stack>
                        </Stack>
                      }
                    />
                    <IconButton edge="end" size="small">
                      <ArrowForward fontSize="small" />
                    </IconButton>
                  </ListItemButton>
                </ListItem>
              </Box>
            ))
          ) : (
            <ListItem sx={{ py: 6, justifyContent: 'center' }}>
              <Stack alignItems="center" spacing={1}>
                <Person sx={{ fontSize: 48, color: 'onSurfaceVariant' }} />
                <Typography color="onSurfaceVariant">No users found</Typography>
              </Stack>
            </ListItem>
          )}
        </List>
      </Card>
    </Stack>
  );
}

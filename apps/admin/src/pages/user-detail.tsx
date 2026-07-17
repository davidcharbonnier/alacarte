import { useState } from 'react';
import {
  Alert,
  Avatar,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  Stack,
  Typography,
} from '@mui/material';
import ArrowBack from '@mui/icons-material/ArrowBack';
import Shield from '@mui/icons-material/Shield';
import Gavel from '@mui/icons-material/Gavel';
import Delete from '@mui/icons-material/Delete';
import Person from '@mui/icons-material/Person';
import Email from '@mui/icons-material/Email';
import CalendarToday from '@mui/icons-material/CalendarToday';
import Visibility from '@mui/icons-material/Visibility';
import Warning from '@mui/icons-material/Warning';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link } from '@tanstack/react-router';
import { formatDistanceToNow } from 'date-fns';
import { userApi } from '../lib/api/users';

export function UserDetailPage({ id }: { id: string }) {
  const userId = parseInt(id, 10);
  const queryClient = useQueryClient();
  const [promoteOpen, setPromoteOpen] = useState(false);
  const [demoteOpen, setDemoteOpen] = useState(false);

  const { data: user, isLoading } = useQuery({
    queryKey: ['users', id],
    queryFn: () => userApi.getById(userId),
  });

  const promoteMutation = useMutation({
    mutationFn: () => userApi.promote(userId),
    onSuccess: () => {
      queryClient.setQueryData(['users', id], (old: any) => ({ ...old, is_admin: true }));
      queryClient.invalidateQueries({ queryKey: ['users', 'list'] });
      setPromoteOpen(false);
    },
  });

  const demoteMutation = useMutation({
    mutationFn: () => userApi.demote(userId),
    onSuccess: () => {
      queryClient.setQueryData(['users', id], (old: any) => ({ ...old, is_admin: false }));
      queryClient.invalidateQueries({ queryKey: ['users', 'list'] });
      setDemoteOpen(false);
    },
  });

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
        <CircularProgress />
      </Box>
    );
  }
  if (!user) return <Typography color="error">User not found</Typography>;

  return (
    <Stack spacing={3}>
      <Stack direction="row" spacing={2} alignItems="center">
        <Button component={Link} to="/users" startIcon={<ArrowBack />}>
          Back to Users
        </Button>
      </Stack>

      <Stack direction={{ xs: 'column', md: 'row' }} spacing={3}>
        <Card variant="outlined" sx={{ flex: 1 }}>
          <CardContent>
            <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
              <Typography variant="h6">User Information</Typography>
              {user.is_admin && <Chip size="small" color="primary" icon={<Shield />} label="Admin" />}
            </Stack>
            <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 3 }}>
              <Avatar src={user.avatar} sx={{ width: 64, height: 64 }}>
                <Person />
              </Avatar>
              <Box>
                <Typography variant="h6">{user.display_name}</Typography>
                <Typography color="text.secondary">{user.full_name}</Typography>
              </Box>
            </Stack>
            <Stack spacing={1.5}>
              <Stack direction="row" spacing={1.5} alignItems="center">
                <Email fontSize="small" color="action" />
                <Typography variant="body2" color="text.secondary">Email:</Typography>
                <Typography variant="body2">{user.email}</Typography>
              </Stack>
              <Stack direction="row" spacing={1.5} alignItems="center">
                <Person fontSize="small" color="action" />
                <Typography variant="body2" color="text.secondary">Google ID:</Typography>
                <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>{user.google_id}</Typography>
              </Stack>
              <Stack direction="row" spacing={1.5} alignItems="center">
                <Visibility fontSize="small" color="action" />
                <Typography variant="body2" color="text.secondary">Discoverable:</Typography>
                <Typography variant="body2">{user.discoverable ? 'Yes' : 'No'}</Typography>
              </Stack>
              <Stack direction="row" spacing={1.5} alignItems="center">
                <CalendarToday fontSize="small" color="action" />
                <Typography variant="body2" color="text.secondary">Joined:</Typography>
                <Typography variant="body2">{new Date(user.created_at).toLocaleDateString()}</Typography>
              </Stack>
              <Stack direction="row" spacing={1.5} alignItems="center">
                <CalendarToday fontSize="small" color="action" />
                <Typography variant="body2" color="text.secondary">Last login:</Typography>
                <Typography variant="body2">
                  {formatDistanceToNow(new Date(user.last_login_at), { addSuffix: true })}
                </Typography>
              </Stack>
            </Stack>
          </CardContent>
        </Card>

        <Card variant="outlined" sx={{ flex: 1 }}>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 1 }}>Admin Actions</Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Manage user permissions and account
            </Typography>
            <Stack spacing={2}>
              <Box>
                <Typography variant="subtitle2" sx={{ mb: 1 }}>Admin Privileges</Typography>
                {user.is_admin ? (
                  <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<Gavel />}
                    onClick={() => setDemoteOpen(true)}
                  >
                    Revoke Admin Privileges
                  </Button>
                ) : (
                  <Button
                    fullWidth
                    variant="contained"
                    startIcon={<Shield />}
                    onClick={() => setPromoteOpen(true)}
                  >
                    Grant Admin Privileges
                  </Button>
                )}
              </Box>
              <Box>
                <Typography variant="subtitle2" sx={{ mb: 1 }}>Danger Zone</Typography>
                <Button
                  fullWidth
                  variant="contained"
                  color="error"
                  component={Link}
                  to={`/users/${user.id}/delete`}
                  startIcon={<Delete />}
                >
                  Delete User Account
                </Button>
              </Box>
            </Stack>
          </CardContent>
        </Card>
      </Stack>

      <ConfirmDialog
        open={promoteOpen}
        onClose={() => setPromoteOpen(false)}
        title="Grant Admin Privileges"
        color="primary"
        message={`You are about to promote ${user.display_name} (${user.email}) to admin. Admins have full access to all data and operations. Only grant admin access to trusted individuals.`}
        onConfirm={() => promoteMutation.mutate()}
        isLoading={promoteMutation.isPending}
        confirmText="Confirm Promotion"
      />
      <ConfirmDialog
        open={demoteOpen}
        onClose={() => setDemoteOpen(false)}
        title="Revoke Admin Privileges"
        color="warning"
        message={`You are about to demote ${user.display_name} (${user.email}). They will lose all admin capabilities but remain a regular user.`}
        onConfirm={() => demoteMutation.mutate()}
        isLoading={demoteMutation.isPending}
        confirmText="Confirm Demotion"
      />
    </Stack>
  );
}

function ConfirmDialog({
  open,
  onClose,
  title,
  message,
  onConfirm,
  isLoading,
  color,
  confirmText,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  message: string;
  onConfirm: () => void;
  isLoading: boolean;
  color: 'primary' | 'warning' | 'error';
  confirmText: string;
}) {
  return (
    <Dialog open={open} onClose={onClose}>
      <DialogTitle>{title}</DialogTitle>
      <DialogContent>
        <Alert severity={color === 'warning' ? 'warning' : color === 'error' ? 'error' : 'info'} icon={<Warning />} sx={{ mb: 2 }}>
          {message}
        </Alert>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={isLoading}>Cancel</Button>
        <Button variant="contained" color={color} onClick={onConfirm} disabled={isLoading}>
          {confirmText}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
